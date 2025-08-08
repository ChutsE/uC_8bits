from interface import Interface
from programs import Programs
import argparse
import time

class Tests(Interface, Programs):
    def __init__(self, test, number_of_cycles, verbose):
        Interface.__init__(self)
        Programs.__init__(self)
        self.test = test
        self.number_of_cycles = number_of_cycles
        self.verbose = verbose
        self.EXECUTION_STATE = 1
        self.FETCH_STATE = 0
        self.establish_connection()
        time.sleep(2)
        try:
            self.program = self.programs[self.test]
        except KeyError:
            print(f"Program '{test}' not found. Defaulting to 'mul'.")
            self.program = self.programs["mul"]

    def run_actions(self, inputs):
        self.enable_tile()
        if self.test == "mul":
            self.program[0x001] = (0x67 << 8) | (inputs[0] & 0xFF)
            self.program[0x002] = (0x68 << 8) | (inputs[1] & 0xFF)
        print("===== Testing Full Cycle =====")
        for i in range(self.number_of_cycles):
            self.load_clock(1, verbose=self.verbose)
            if self.cu_state == self.EXECUTION_STATE:
                self.load_instruction(self.program[self.program_counter])
            self.flush(verbose=self.verbose)
        print("===== End of Full Cycle Test =====")
        self.serial.close()


def main():
    parser = argparse.ArgumentParser(description="Run tests on the microcontroller programs.")
    parser.add_argument("--test", type=str, default="mul", help="Specify the test to run (default: mul).")
    parser.add_argument("--cycles", type=int, default=1000, help="Number of cycles to run the test (default: 1000).")
    parser.add_argument("--verbose", action="store_true", default=False, help="Enable verbose output.")
    parser.add_argument("--inputs", type=int, nargs='+', default=[9, 4], help="Input(s), space separated (default: 9 4) [int].")
    args = parser.parse_args()

    test = Tests(test=args.test, number_of_cycles=args.cycles, verbose=args.verbose)
    test.run_actions(args.inputs)
    print("Test completed successfully.")

if __name__ == "__main__":
    main()