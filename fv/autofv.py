import os
import re
import logging
import sys

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

def _read_file_content(filepath):
    """
    Read and return the entire content of a file.

    Args:
        filepath (str): The path to the file to be read.

    Returns:
        str: The complete content of the file as a string.

    """
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def _is_sv_or_v_file(filename):
    """
    Check if a file is a SystemVerilog or Verilog source file.
    Determines whether the given filename has a .sv (SystemVerilog) or .v (Verilog)
    file extension, performing a case-insensitive comparison.
    Args:
        filename (str): The name of the file to check.
    Returns:
        bool: True if the filename ends with .sv or .v extension (case-insensitive),
              False otherwise.
    """

    return filename.lower().endswith(('.sv', '.v'))

def _get_files_from_directory(directory, recursive=False):
    """
    Retrieve a list of Verilog or SystemVerilog files from a directory.
    This function searches for files with Verilog (.v) or SystemVerilog (.sv) extensions
    in the specified directory. It supports both non-recursive and recursive directory traversal.
    Args:
        directory (str): The path to the directory to search for Verilog/SystemVerilog files.
        recursive (bool, optional): If True, recursively searches subdirectories. 
                                   If False, searches only the specified directory. 
                                   Defaults to False.
    Returns:
        list: A list of absolute file paths to Verilog or SystemVerilog files found in the directory.
              Returns an empty list if no matching files are found.
    """

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
    """
    Generate SystemVerilog formal verification (FV) module files from storage content.
    This function processes Verilog module definitions from a storage dictionary and creates
    corresponding formal verification wrapper modules. It extracts module declarations, input/output
    ports, and generates FV module instances with bind statements for verification purposes.
    Args:
        storage (dict): A dictionary where keys are file paths and values are file contents
                       containing Verilog module definitions.
        output_dir (str or None): The output directory where generated FV files will be saved.
                                 If None, files are generated relative to the original file path.
    Returns:
        int: 0 if all files are processed successfully, 1 if an exception occurs during file creation.
    Behavior:
        - Iterates through each file in storage
        - Parses module declarations and extracts module name and parameters
        - Collects input and output port declarations
        - Creates a new FV module with:
            * Prefixed name (fv_<module_name>)
            * Same parameters and ports as the original module
            * Conditional defines for TOP, ASM, COV, and REUSE configurations
            * A bind statement to instantiate the FV module
        - Skips files that don't contain valid module declarations
        - Prevents overwriting existing FV files
        - Logs all operations (info, warning, and error levels)
    Raises:
        Logs exceptions if file creation fails but doesn't propagate them.
    """
    for path, content in storage.items():
        logger.info(f"\nArchivo: {path}")
        lines = content.splitlines()
        input_lines = []
        module_name = None

        module_found = False
        accumulating_params = False
        accumulated_params = ""
        in_block_comment = False
        
        for line in lines:
            # Handle block comments /* */
            if '/*' in line:
                in_block_comment = True
            if '*/' in line:
                in_block_comment = False
                continue
            if in_block_comment:
                continue
            
            stripped_line = line.strip()
            if stripped_line.startswith("//"):
                continue
            code_line = line.split("//")[0].strip()

            if accumulating_params:
                accumulated_params += " " + code_line.strip()
                if ')' in code_line:
                    param_end = accumulated_params.find(')')
                    if param_end != -1:
                        final_params = accumulated_params[:param_end].strip()
                        logger.info(f"module {module_name} #({final_params}) (")
                        input_lines.append(f"module fv_{module_name} #({final_params}) (")
                        accumulating_params = False
                        accumulated_params = ""
                continue

            module_match = re.match(r'\s*module\s+(\w+)\s*(?:#\s*\((.*?)\))?', code_line, re.S)
            if module_match:
                module_found = True
                module_name = module_match.group(1)
                module_params = module_match.group(2)
                
                if '#' in code_line and '(' in code_line and ')' not in code_line:
                    accumulating_params = True
                    param_start = code_line.find('(')
                    accumulated_params = code_line[param_start+1:].strip()
                elif module_params:
                    logger.info(f"module {module_name} #({module_params}) (")
                    input_lines.append(f"module fv_{module_name} #({module_params}) (")
                else:
                    logger.info(f"module {module_name} (")
                    input_lines.append(f"module fv_{module_name} (")
                continue
            input_match = re.search(r'\binput\b(.*)', code_line)
            if input_match:
                captured = input_match.group(1).split("//")[0].strip()
                if captured: 
                    input_line = "input " + captured
                    logger.info(input_line)
                    input_lines.append(input_line)
            output_match = re.search(r'\boutput\b(.*)', code_line)
            if output_match:
                captured = output_match.group(1).split("//")[0].strip()
                if captured: 
                    output_line = "input " + captured
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
            logger.warning(f"No module found in file {path}. FV file creation will be skipped.")
            continue
        else:
            base_filename = "fv_" + os.path.splitext(os.path.basename(path))[0] + ".sv"
            if output_dir:
                new_filename = os.path.join(output_dir, base_filename)
            else:
                new_filename =  "fv_" + os.path.splitext(path)[0] + ".sv"
            if os.path.exists(new_filename):
                logger.warning(f"File {new_filename} already exists. File creation will be skipped.")
                continue
            try:
                os.makedirs(os.path.dirname(new_filename), exist_ok=True)
                with open(new_filename, 'w', encoding='utf-8') as f:
                    for input_line in input_lines:
                        f.write(input_line + '\n')
                logger.info(f"FV file created: {new_filename}")
            except Exception:
                logger.exception(f"Could not create file {new_filename}")
                return 1
    return 0

def macros_creation(output_dir):
    """
    Creates a SystemVerilog header file with property definition macros.
    
    This function generates a file named 'property_defines.svh' containing reusable
    macros for defining assertions, assumptions, and coverage properties in SystemVerilog.
    The macros include AST (assert), ASM (assume), COV (cover), and REUSE for flexible
    property specification with customizable block names, preconditions, and consequences.
    
    Args:
        output_dir (str or None): The directory where the 'property_defines.svh' file
                                  will be created. If None or empty, the file is created
                                  in the current working directory.
    
    Returns:
        int: Returns 0 on successful file creation, 1 if an error occurs during file
             creation or directory setup.
    
    """
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
    """
    Creates a Makefile with targets for each RTL file.
    This function generates a Makefile containing build targets for multiple RTL (Register Transfer Level)
    files. Each target executes a JasperGold FPV (Formal Property Verification) script with specific
    definitions based on the RTL file names.
    Args:
        rtl_files_paths (list): A list of file paths to RTL files. The function extracts the base
                               filename from each path to create corresponding Makefile targets.
        output_dir (str): The output directory where the Makefile will be created. If None or empty,
                         the Makefile is created in the current directory.
    Returns:
        int: Returns 0 on successful Makefile creation, returns 1 if an exception occurs during
             file creation or writing.
    """
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
    """
    Generate a Verilog/SystemVerilog file list (flist) for formal verification.
    This function creates an 'analyze.flist' file containing include directories,
    RTL file paths, and formal verification file references. The flist is commonly
    used by simulation and formal verification tools to compile and analyze designs.
    Args:
        rtl_files_paths (list): List of paths to RTL source files to be included
                               in the file list.
        output_dir (str): Output directory where the 'analyze.flist' file will be
                         created. If None or empty, defaults to current directory.
    Returns:
        int: Returns 0 on successful creation, 1 if an error occurred while
             writing the flist file.

    """
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
    """
    Generates a TCL script file for formal verification analysis using Jasper.
    This function creates a TCL configuration file that defines design analysis options,
    elaboration parameters, clock and reset specifications, and formal verification
    proof directives for hardware design verification.
    Args:
        storage (dict): Dictionary containing file paths as keys, used to extract
                       design top module names for conditional defines.
        output_dir (str): Directory path where the TCL script will be written.
                         If empty or None, defaults to the current directory.
    Returns:
        int: Returns 0 on successful creation, 1 if an error occurred while
             writing the TCL file.
    """
    
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
        return 0
    except Exception:
        logger.exception("No se pudo crear el archivo TCL")
        return 1

def window_main():
    import tkinter as tk
    from tkinter import filedialog, messagebox

    root = tk.Tk()
    root.title("AutoFV Generator")
    root.geometry("500x450")
    
    storage = {}
    selected_output_dir = [None]
    
    def browse_file():
        filepath = filedialog.askopenfilename(
            title="Select RTL Design File",
            filetypes=[("Verilog/SystemVerilog", "*.sv *.v"), ("All Files", "*.*")]
        )
        if filepath and _is_sv_or_v_file(filepath):
            storage.clear()
            storage[filepath] = _read_file_content(filepath)
            logger.info(f"Stored content of {filepath}")
            messagebox.showinfo("Success", f"File loaded: {filepath}")
            file_label.config(text=f"File: {filepath}")
        elif filepath:
            messagebox.showerror("Error", "Invalid file type. Please select .sv or .v file.")
    
    def browse_directory():
        dirpath = filedialog.askdirectory(title="Select Directory with RTL Files")
        if dirpath:
            storage.clear()
            files = _get_files_from_directory(dirpath, recursive=False)
            if files:
                for file in files:
                    try:
                        storage[file] = _read_file_content(file)
                        logger.info(f"Stored content of {file}")
                    except Exception:
                        logger.exception(f"Could not read {file}")
                messagebox.showinfo("Success", f"Loaded {len(files)} file(s)")
                file_label.config(text=f"Directory: {len(files)} file(s) loaded")
            else:
                messagebox.showwarning("Warning", "No .sv or .v files found in directory.")
    
    def browse_output_dir():
        dirpath = filedialog.askdirectory(title="Select Output Directory")
        if dirpath:
            selected_output_dir[0] = dirpath
            output_label.config(text=f"Output: {dirpath}")
    
    def generate_files():
        if not storage:
            messagebox.showerror("Error", "No files loaded. Please load RTL files first.")
            return
        
        if not selected_output_dir[0]:
            messagebox.showerror("Error", "Please select an output directory.")
            return
        
        output_dir = selected_output_dir[0]
        
        try:
            results = []
            
            ret = fv_files_creation(storage, output_dir)
            results.append(("FV files", ret))
            
            ret = macros_creation(output_dir)
            results.append(("Property defines file", ret))
            
            ret = makefile_creation(list(storage.keys()), output_dir)
            results.append(("Makefile", ret))
            
            ret = flist_creation(list(storage.keys()), output_dir)
            results.append(("File list (flist)", ret))
            
            ret = tcl_creation(storage, output_dir)
            results.append(("TCL script", ret))
            
            summary = "File Generation Summary:\n\n"
            all_success = True
            for task_name, return_code in results:
                status = "  ✓ Success" if return_code == 0 else "  ✗ Failed"
                summary += f"{task_name}: {status}\n"
                if return_code != 0:
                    all_success = False
            
            if all_success:
                messagebox.showinfo("Generation Complete", summary)
            else:
                messagebox.showwarning("Generation Complete", summary)
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
    

    title_label = tk.Label(root, text="AutoFV Generator", font=("Arial", 14, "bold"))
    title_label.pack(pady=10)
    

    frame1 = tk.LabelFrame(root, text="Load RTL Files", padx=10, pady=10)
    frame1.pack(padx=10, pady=5, fill="x")
    
    tk.Button(frame1, text="Browse Single File", command=browse_file, width=30).pack(pady=5)
    tk.Button(frame1, text="Browse Directory", command=browse_directory, width=30).pack(pady=5)
    
    file_label = tk.Label(frame1, text="No files loaded", fg="gray", wraplength=400)
    file_label.pack(pady=5)
    
    frame2 = tk.LabelFrame(root, text="Select Output Directory", padx=10, pady=10)
    frame2.pack(padx=10, pady=5, fill="x")
    
    tk.Button(frame2, text="Browse Output Directory", command=browse_output_dir, width=30).pack(pady=5)
    
    output_label = tk.Label(frame2, text="No output directory selected", fg="gray", wraplength=400)
    output_label.pack(pady=5)
    
    frame3 = tk.Frame(root)
    frame3.pack(padx=10, pady=15, fill="x")
    
    tk.Button(frame3, text="Generate FV Framework", command=generate_files, bg="green", fg="white", 
              font=("Arial", 12, "bold"), width=30).pack(pady=10)
    
    root.mainloop()

def cli_main(args):
    """
    Command-line interface for AutoJasper-FPV File Generator.
    Provides interactive prompts for file selection, output directory, and generation.
    """
    storage = {}
    if args.file:
        if _is_sv_or_v_file(args.file):
            storage[args.file] = _read_file_content(args.file)
            logger.info(f"Loaded file: {args.file}")
        else:
            logger.error("Invalid file type. Please select .sv or .v file.")
            return 1
    elif args.directory:
        files = _get_files_from_directory(args.directory, recursive=args.recursive)
        if files:
            for file in files:
                storage[file] = _read_file_content(file)
            logger.info(f"Loaded {len(files)} file(s) from {args.directory}")
        else:
            logger.error("No .sv or .v files found.")
            return 1
    else:
        parser.print_help()
        return 1
    
    if not os.path.exists(args.output):
        os.makedirs(args.output)
    
    logger.info(f"Output directory: {args.output}\n")
    
    ret_fv = fv_files_creation(storage, args.output)
    ret_macros = macros_creation(args.output)
    ret_makefile = makefile_creation(list(storage.keys()), args.output)
    ret_flist = flist_creation(list(storage.keys()), args.output)
    ret_tcl = tcl_creation(storage, args.output)
    
    results = [
        ("FV files", ret_fv),
        ("Property defines", ret_macros),
        ("Makefile", ret_makefile),
        ("File list", ret_flist),
        ("TCL script", ret_tcl)
    ]
    
    logger.info("\n" + "="*50)
    logger.info("Generation Summary:")
    logger.info("="*50)
    all_success = True
    for task, ret in results:
        status = "✓ Success" if ret == 0 else "✗ Failed"
        logger.info(f"{task}: {status}")
        if ret != 0:
            all_success = False
    
    return 0 if all_success else 1


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="AutoJasper-FPV File Generator - Generate formal verification framework"
    )
    parser.add_argument(
        "-f", "--file",
        type=str,
        default=None,
        help="Path to a single RTL file (.sv or .v)"
    )
    parser.add_argument(
        "-d", "--directory",
        type=str,
        default=None,
        help="Path to directory containing RTL files"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default=None,
        help="Output directory for generated files"
    )
    parser.add_argument(
        "-r", "--recursive",
        default=False,
        action="store_true",
        help="Recursively search subdirectories"
    )
    
    args = parser.parse_args()

    if (args.file or args.directory) and args.output:
        try:
            return_code = cli_main(args)
        except Exception as e:
            logger.exception(f"An error occurred: {str(e)}")
            return_code = 1
    else:
        try:
            return_code = window_main()
        except Exception as e:
            logger.exception(f"An error occurred in window mode: {str(e)}")
            return_code = 1
    sys.exit(return_code)