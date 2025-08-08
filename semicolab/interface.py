from csr import Csr

class Interface(Csr):
    def __init__(self):
        super().__init__()
        self.tile_num = 0x0F
        self.data_reg_c = 0
        self.csr_in = 0
        self.program_counter = 0
        self.cu_state = 0
        self.data_reg_a = 0
        
    def refresh(self, verbose=True):
        self.data_reg_c = self.read_csr(3)
        self.program_counter = (self.data_reg_c) & 0xFFF
        self.cu_state = (self.data_reg_c >> 12) & 0x01
        if verbose:
            print("Program Counter: " + "{:08X}".format(self.program_counter))
            print("CU State: " + "{:08X}".format(self.cu_state))

    def load_instruction(self, instruction, verbose=True):
        self.data_reg_a = instruction & 0xFFFF
        if verbose:
            print("inst: " + "{:08X}".format(self.data_reg_a))

    def load_clock(self, clock, verbose=True):
        self.csr_in = (self.csr_in & ~(1 << 15)) | ((clock & 0x1) << 15)
        if verbose:
            print("Setting clock: " + "{:08X}".format(self.csr_in))

    def flush(self, verbose=True):
        self.write_csr(1, self.data_reg_a)
        self.write_csr(0, self.csr_in)
        if verbose:
            print("Flushing all CSR data")
        self.refresh(verbose=verbose)
    
    def enable_tile(self, tile = 0x0F):
        self.write_csr(14,0x00000000) # Clear client & owner enable
        self.write_csr(0,0xC2F29023) # Enable harness
        self.read_client_name() # Read and print client name
        self.write_csr(0,self.tile_num) # Enable tile
        self.read_owner_name() # Read Tile owner name
        self.read_owner_name() # Save owner name to owner variable