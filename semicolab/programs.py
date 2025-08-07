class Programs:
    def __init__(self):
        self.programs = {
            "mul" : {
                ### BOOTSTRAPPING ###
                0x000: 0x0000, # NOP
                0x001: 0x6707, # IN A to R7
                0x002: 0x6804, # IN B to R8
                0x003: 0x6901, # IN 0x1 to R9
                0x004: 0x6A00, # IN 0x0 to R10
                0x005: 0x6B00, # IN 0x0 to R11
                0x006: 0x6C00, # IN 0x0 to R12
                0x007: 0x2701, # STORE R7 -> MEM[0x1]
                0x008: 0x2802, # STORE R8 -> MEM[0x2]
                0x009: 0x2903, # STORE R9 -> MEM[0x3]
                0x00A: 0x2A04, # STORE R10 -> MEM[0x4]
                0x00B: 0x2B05, # STORE R11 -> MEM[0x5]
                0x00C: 0x2C06, # STORE R12 -> MEM[0x6]

                0x00D: 0x3200, # JMP 0x200
                0x00E: 0x0000, # NOP

                ### MULTIPLICATION PROGRAM ###
                0x200: 0x1101, # LOAD R1 <- MEM[0x1] 
                0x201: 0x1202, # LOAD R2 <- MEM[0x2]
                0x202: 0x1303, # LOAD R3 <- MEM[0x3]
                0x203: 0x1404, # LOAD R4 <- MEM[0x4]
                0x204: 0x1505, # LOAD R5 <- MEM[0x5]
                0x205: 0x1606, # LOAD R6 <- MEM[0x6]
                0x206: 0x0000, # NOP
                0x207: 0x7200, # OUT R1 port 0
                0x208: 0xD025, # CMP R2, R5
                0x209: 0x4350, # BEQ 0x350
                0x20A: 0x0000, # NOP
                0x20B: 0x8616, # ADD R6 = R1 + R6
                0x20C: 0x5250, # BC 0x250
                0x20D: 0x0000, # NOP
                0x20E: 0x3300, # JMP 0x300
                0x20F: 0x0000, # NOP

                ### CARRY ###
                0x250: 0x8443, # ADD R4 = R4 - R3
                0x251: 0x3300, # JMP 0x300
                0x252: 0x0000, # NOP

                ### SUB B - 1 ###
                0x300: 0x9223, # SUB R2 = R2 - R3
                0x301: 0x3206, # JMP 0x206
                0x302: 0x0000, # NOP

                ### END OF PROGRAM ###
                0x350: 0x7600, # OUT R6 port 0
                0x351: 0x7401, # OUT R4 port 1
                0x352: 0x3350, # JMP 0x350
                0x353: 0x0000, # NOP
            }
        }
