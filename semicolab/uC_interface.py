from Csr_Com_Class import CsrComClass

class UCInterface(CsrComClass):
    def __init__(self):
        super().__init__()
        self.data_reg_c = 0
        self.data_csr_out = 0
        self.program_counter = 0
        self.sram_address = 0
        self.sram_data = 0
        self.sram_write_enable = 0
        self.cu_state = 0

        self.data_reg_a = 0
        self.data_reg_b = 0
        
    def refresh(self, verbose=True):
        self.data_reg_c = self.read_csr(3)
        self.program_counter = (self.data_reg_c >> 16) & 0xFFF
        self.sram_address = (self.data_reg_c >> 4) & 0xFFF
        self.sram_data = (self.data_reg_c >> 8) & 0xFF
        self.sram_write_enable = (self.data_reg_c >> 31) & 0x01
        self.cu_state = (self.data_reg_c >> 29) & 0x01
        if verbose:
            print("Program Counter: " + "{:08X}".format(self.program_counter))
            print("CU State: " + "{:08X}".format(self.cu_state))

    def get_gpio_output_0(self, out_gpio):
        gpio_output_0 = (out_gpio) & 0xFF
        print("Getting GPIO output: " + "{:08X}".format(gpio_output_0))
        return gpio_output_0
    
    def get_gpio_output_1(self, out_gpio):
        gpio_output_1 = (out_gpio >> 8) & 0xFF
        print("Getting GPIO output: " + "{:08X}".format(gpio_output_1))
        return gpio_output_1

    def load_instruction(self, instruction, verbose=True):
        self.data_reg_a = (self.data_reg_a & ~(1 << 8)) | (0x1 << 8)
        self.data_reg_b = instruction & 0xFFFF
        if verbose:
            print("Setting instruction: " + "{:08X}".format(self.data_reg_b))

    def load_sram_data(self, data, verbose=True):
        self.data_reg_a = data & 0xFF
        if verbose:
            print("Setting SRAM data: " + "{:08X}".format(self.data_reg_a))

    def load_clock(self, clock, verbose=True):
        self.data_reg_a = (self.data_reg_a & ~(1 << 9)) | ((clock & 0x1) << 9)
        if verbose:
            print("Setting clock: " + "{:08X}".format(self.data_reg_a))

    def flush(self, verbose=True):
        self.write_csr(1, self.data_reg_a)
        self.write_csr(2, self.data_reg_b)
        if verbose:
            print("Flushing all CSR data")
        self.refresh(verbose=verbose)
    
    def enable_tile(self, tile = 0x0F):
        self.write_csr(14,0x00000000) # Clear client & owner enable
        self.write_csr(0,0xC2F29023) # Enable harness
        self.read_client_name() # Read and print client name
        self.write_csr(0,tile) # Enable tile
        self.read_owner_name() # Read Tile owner name
        self.read_owner_name() # Save owner name to owner variable