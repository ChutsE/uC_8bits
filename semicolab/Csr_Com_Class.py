import serial
from serial.tools import list_ports
import numpy as np
import struct

class CsrComClass:
    def __init__(self, port_name=None, baudrate=115200):
        self.port_name = port_name
        if not self.port_name:
            ports = list_ports.comports()
            if ports:
                print("Available serial ports:")
                for port in ports:
                    print(f"  Device: {port.device}")
                    print(f"  Name: {port.name}")
                    print(f"  Description: {port.description}")
                    print(f"  Hardware ID: {port.hwid}")
                    print("-" * 30)
                    try:
                        self.port_name = str(port.name)
                        self.serial = serial.Serial(self.port_name, baudrate=baudrate)
                        print("Succesfully connected to uart slave")
                        break
                    except Exception as e:
                        print(f"Could not connect to uart slave: {e}")
                        continue
            else:
                print("No serial ports found.")
        else:
            try:
                self.serial = serial.Serial(self.port_name, baudrate=baudrate)
                print(f"Could not connect to uart slave: {e}")
            except:
                print("Could not connect to uart slave")

    def ser_wr_rd(self, data):
        self.serial.write(data)
        val = self.serial.read(np.size(data))

    def write_csr(self, addr, data):
        COMMAND = 1
        v = struct.pack('B', COMMAND)
        self.ser_wr_rd(v)
        v = struct.pack('B', addr) # B - 1 Byte, H - 2 Bytes, I - 4 Bytes, Q - 8 Bytes
        self.ser_wr_rd(v)
        v = struct.pack('I', data)
        self.ser_wr_rd(v)
        print("wrote " + "{:08X}".format(data) )
        self.serial.reset_input_buffer()

    def read_csr(self, addr):
        COMMAND = 0
        v = struct.pack('B', COMMAND)
        self.ser_wr_rd(v)
        v = struct.pack('B', addr) # B - 1 Byte, H - 2 Bytes, I - 4 Bytes, Q - 8 Bytes
        self.ser_wr_rd(v)
        v = struct.pack('I', 0)
        self.serial.write(v)
        while(self.serial.in_waiting < 4):()
        val = self.serial.read(4)
        data_received = int.from_bytes(val, "little")
        print("Read  " + "{:08X}".format(data_received) )
        return(data_received)

    def read_client_name(self):
        COMMAND = 0
        string_received = ""
        for i in range(8,3,-1):
            v = struct.pack('B', COMMAND)
            self.ser_wr_rd(v)
            v = struct.pack('B', i) # B - 1 Byte, H - 2 Bytes, I - 4 Bytes, Q - 8 Bytes
            self.ser_wr_rd(v)
            v = struct.pack('I', 0)
            self.serial.write(v)
            while(self.serial.in_waiting < 4):()
            val = self.serial.read(4)
            string_received = string_received + val[::-1].decode('utf-8')
        print(string_received)

    def read_owner_name(self):
        COMMAND = 0
        string_received = ""
        for i in range(13,8,-1):
            v = struct.pack('B', COMMAND)
            self.ser_wr_rd(v)
            v = struct.pack('B', i) # B - 1 Byte, H - 2 Bytes, I - 4 Bytes, Q - 8 Bytes
            self.ser_wr_rd(v)
            v = struct.pack('I', 0)
            self.serial.write(v)
            while(self.serial.in_waiting < 4):()
            val = self.serial.read(4)
            string_received = string_received + val[::-1].decode('utf-8')
        print(string_received)
        return(string_received)

    def transfer(self, bt):
        v = struct.pack('B', bt)
        self.serial.write(v)