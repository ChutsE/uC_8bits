from uC_interface import UCInterface
from programs import Programs

class UCTests(UCInterface, Programs):
    def __init__(self, test = "mul"):
        UCInterface.__init__(self)
        Programs.__init__(self)
        self.EXECUTION_STATE = 1
        self.FETCH_STATE = 0
        if test == "mul":
            self.program = self.mul_program
        else:
            print("No program selected")
            self.program = {}
        

    def run_actions(self):
        self.enable_tile()
        print("===== Testing Full Cycle =====")
        for i in range(2000):

            self.load_clock(1)
            if self.cu_state == self.EXECUTION_STATE:
                self.load_instruction(self.program[self.program_counter])
            self.flush()
            self.load_clock(0)
            self.flush()
        print("===== End of Full Cycle Test =====")