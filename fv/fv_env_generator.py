import os
import re
import logging
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

def _read_file_content(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def _is_sv_or_v_file(filename):
    return filename.lower().endswith(('.sv', '.v'))

def _get_files_from_directory(directory, recursive=False):
    files = []
    if recursive:
        for root, _, filenames in os.walk(directory):
            for filename in filenames:
                if _is_sv_or_v_file(filename):
                    files.append(os.path.join(root, filename))
    else:
        for filename in os.listdir(directory):
            full_path = os.path.join(directory, filename)
            if os.path.isfile(full_path) and _is_sv_or_v_file(filename):
                files.append(full_path)
    return files


def fv_files_creation(storage, output_dir):
    for path, content in storage.items():
        logger.info(f"\nArchivo: {path}")
        lines = content.splitlines()
        input_lines = []
        module_name = None

        module_found = False
        for line in lines:
            stripped_line = line.strip()
            if stripped_line.startswith("//"):
                continue
            code_line = line.split("//")[0]

            module_match = re.match(r'\s*module\s+(\w+)\s*(?:#\s*\((.*?)\))?', code_line, re.S)
            if module_match:
                module_found = True
                module_name = module_match.group(1)
                module_params = module_match.group(2)
                if module_params:
                    logger.info(f"module {module_name} #({module_params}) (")
                    input_lines.append(f"module fv_{module_name} #({module_params}) (")
                else:
                    logger.info(f"module {module_name} (")
                    input_lines.append(f"module fv_{module_name} (")
                module_match = None
            input_match = re.search(r'\binput\b(.*)', code_line)
            if input_match:
                input_line = "input" + input_match.group(1)
                logger.info(input_line)
                input_lines.append(input_line)
            output_match = re.search(r'\boutput\b(.*)', code_line)
            if output_match:
                output_line = "input" + output_match.group(1)
                logger.info(output_line)
                input_lines.append(output_line)
            endmodule_match = re.match(r'\bendmodule\b(.*)', code_line)
            if endmodule_match:
                logger.info("endmodule")
                input_lines.append(");")
                input_lines.append(f"  `ifdef {module_name.upper()}_TOP ")
                input_lines.append(f"    `define {module_name.upper()}_ASM 1")
                input_lines.append("  `else")
                input_lines.append(f"    `define {module_name.upper()}_ASM 0")
                input_lines.append("  `endif")
                input_lines.append("  ")
                input_lines.append("  // Here add yours AST, COV, ASM, REUSE etc.")
                input_lines.append("  ")
                input_lines.append("endmodule")
                input_lines.append("")
                input_lines.append(f"bind {module_name} fv_{module_name} fv_{module_name}_i(.*);")
                input_lines.append("")

        if not module_found:
            logger.warning(f"No se encontró un módulo en el archivo {path}. Se omitirá la creación del archivo FV.")
            continue
        else:
            base_filename = "fv_" + os.path.splitext(os.path.basename(path))[0] + ".sv"
            if output_dir:
                new_filename = os.path.join(output_dir, base_filename)
            else:
                new_filename =  "fv_" + os.path.splitext(path)[0] + ".sv"
            if os.path.exists(new_filename):
                logger.warning(f"El archivo {new_filename} ya existe. Se omitirá la creación.")
                continue
            try:
                os.makedirs(os.path.dirname(new_filename), exist_ok=True)
                with open(new_filename, 'w', encoding='utf-8') as f:
                    for input_line in input_lines:
                        f.write(input_line + '\n')
                logger.info(f"Archivo de inputs creado: {new_filename}")
            except Exception:
                logger.exception(f"No se pudo crear el archivo {new_filename}")
                return 1
    return 0

def macros_creation(output_dir):
    svh_content = (
        "`define AST(block=rca, name=no_name, precond=1'b1 |->, consq=1'b0) \\\n"
        "``block``_ast_``name``: assert property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);\n\n"
        "`define ASM(block=rca, name=no_name, precond=1'b1 |->, consq=1'b0) \\\n"
        "``block``_ast_``name``: assume property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);\n\n"
        "`define COV(block=rca, name=no_name, precond=1'b1 |->, consq=1'b0) \\\n"
        "``block``_ast_``name``: cover property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``);\n\n"
        "`define REUSE(top=1'b0, block=no_name, name=no_name, precond=1'b1 |->, consq=1'b0) \\\n"
        "  if(top==1'b1) begin \\\n"
        "  ``block``_asm_``name``: assume property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``); \\\n"
        "  end else begin \\\n"
        "  ``block``_ast_``name``: assert property (@(posedge clk) disable iff(!arst_n) ``precond`` ``consq``); \\\n"
        "  end"
    )
    svh_path = os.path.join(output_dir if output_dir else ".", "property_defines.svh")
    try:
        os.makedirs(os.path.dirname(svh_path), exist_ok=True)
        with open(svh_path, "w", encoding="utf-8") as f:
            f.write(svh_content)
        logger.info(f"Archivo property_defines.svh creado en: {svh_path}")
        return 0
    except Exception:
        logger.exception("No se pudo crear el archivo property_defines.svh")
        return 1

def makefile_creation(rtl_files_paths, output_dir):
    makefile_lines = []
    for rtl_path in rtl_files_paths:
        base_filename = os.path.splitext(os.path.basename(rtl_path))[0]
        makefile_lines.append(f"{base_filename.lower()}_top:")
        makefile_lines.append(f"\tjg jg_fpv.tcl -allow_unsupported_OS -define {base_filename.upper()}_TOP 1&")
        makefile_lines.append("")

    makefile_path = os.path.join(output_dir if output_dir else ".", f"Makefile")
    try:
        os.makedirs(os.path.dirname(makefile_path), exist_ok=True)
        with open(makefile_path, "w", encoding="utf-8") as f:
            for line in makefile_lines:
                f.write(line + "\n")
        logger.info(f"Archivo Makefile creado en: {makefile_path}")
        return 0
    except Exception:
        logger.exception(f"No se pudo crear el archivo Makefile para {base_filename}")
        return 1

def flist_creation(rtl_files_paths, output_dir):
    flist_lines = [
        "+incdir+.",
        "",
        "# Definitions for RTL configurations",
        "   # Add here your `define statements for RTL configurations",
        "",
        "# Formal properies macros",
        "./property_defines.svh"]
    
    # Add RTL files
    flist_lines.append("")
    flist_lines.append("# RTL design files")
    for rtl_path in rtl_files_paths:
        flist_lines.append("../rtl/" + os.path.basename(rtl_path))
    
    # Add FV files if output_dir exists
    flist_lines.append("")
    flist_lines.append("# Formal verification files")
    for rtl_path in rtl_files_paths:
        base = os.path.splitext(os.path.basename(rtl_path))[0]
        flist_lines.append("./fv_" + base + ".sv")
    
    flist_path = os.path.join(output_dir if output_dir else ".", "analyze.flist")
    
    try:
        os.makedirs(os.path.dirname(flist_path), exist_ok=True)
        with open(flist_path, "w", encoding="utf-8") as f:
            for line in flist_lines:
                f.write(line + "\n")
        logger.info(f"Archivo flist creado en: {flist_path}")
        return 0
    except Exception:
        logger.exception("No se pudo crear el archivo flist")
        return 1

def tcl_creation(storage, output_dir):
    
    tcl_lines = [
        "clear -all",
        "",
        "set_proofgrid_bridge off",
        "",
        "set fv_analyze_options { -sv12 }",
        "set design_top shifting_cell"
    ]

    for path in storage.keys():
        base = os.path.splitext(os.path.basename(path))[0]
        tcl_lines.append("")
        tcl_lines.append("if {[info exists " + str(base).upper() + "_TOP]} {")
        tcl_lines.append("  lappend fv_analyze +define+" + str(base).upper() + "_TOP")
        tcl_lines.append("  set design_top " + str(base).lower())
        tcl_lines.append("}")

    
    tcl_lines.append("")
    tcl_lines.append("analyze [join $fv_analyze_options] -f analyze.flist")
    tcl_lines.append("")

    tcl_lines.append("elaborate -bbox_a 65535 -bbox_mul 65535 -non_constant_loop_limit 2000 -top $design_top")
    tcl_lines.append("get_design_info")
    tcl_lines.append("")
    tcl_lines.append("clock clk")
    tcl_lines.append("reset -expression !arst_n")
    tcl_lines.append("set_engineJ_max_trace_length 2000")
    tcl_lines.append("")
    tcl_lines.append("prove -all")
    tcl_lines.append("")

    tcl_path = os.path.join(output_dir if output_dir else ".", "jg_fpv.tcl")
    try:
        with open(tcl_path, "w", encoding="utf-8") as f:
            for line in tcl_lines:
                f.write(line + "\n")
        logger.info(f"Archivo TCL creado en: {tcl_path}")
    except Exception:
        logger.exception("No se pudo crear el archivo TCL")

def main():
    storage = {}
    logger.info("Menu:")
    logger.info("1. Enter the file path")
    logger.info("2. Enter a directory path (without recursion)")
    choice = input("Choose an option (1 or 2): ").strip()
    logger.info(f"You chose option {choice}")
    if choice == '1':
        filepath = input("Enter the file path where is located your RTL design: ").strip()
        if os.path.isfile(filepath) and _is_sv_or_v_file(filepath):
            storage[filepath] = _read_file_content(filepath)
            logger.info(f"Stored content of {filepath}")
        else:
            logger.error("Invalid file path or not a .sv/.v file.")
            return 3
    elif choice == '2':
        dirpath = input("Enter the directory path where your RTL design files are located: ").strip()
        if os.path.isdir(dirpath):
            files = _get_files_from_directory(dirpath, recursive=False)
            for file in files:
                try:
                    storage[file] = _read_file_content(file)
                    logger.info(f"Stored content of {file}")
                except Exception:
                    logger.exception(f"Could not read {file}")
                    return 3
        else:
            logger.error("Invalid directory path.")
            return 2
    else:
        logger.error("Invalid choice.")
        return 1
    
    if len(storage) == 0:
        logger.error("No valid .sv or .v files found.")
        return 4

    output_dir = input("\nEnter the directory where you want to save the result files: ").strip()
   

    ret = fv_files_creation(storage, output_dir)
    if ret != 0:
        return ret
    ret = macros_creation(output_dir)
    if ret != 0:
        return ret
    ret = makefile_creation(list(storage.keys()), output_dir)
    if ret != 0:
        return ret
    ret = flist_creation(list(storage.keys()), output_dir)
    if ret != 0:
        return ret
    ret = tcl_creation(storage, output_dir)
    if ret != 0:
        return ret
    return 0

if __name__ == "__main__":
    sys.exit(main())