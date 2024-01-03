import sys

def crc16(data : bytearray, offset , length):
    if data is None or offset < 0 or offset > len(data)- 1 and offset+length > len(data):
        return 0
    crc = 0xFFFF
    for i in range(0, length):
        crc ^= data[offset + i] << 8
        for j in range(0,8):
            if (crc & 0x8000) > 0:
                crc =(crc << 1) ^ 0x1021
            else:
                crc = crc << 1
    return crc & 0xFFFF

def main(argv):
    print ("ROMCheck Utility")
    print ("From zx-diagnostics, Brendan Alford 2024")
    if (len(argv) != 1):
        print ("Incorrect number of arguments. Please provide filename of ROM file to checksum")
        exit()
    romFile = open(argv[0], 'rb')
    romBytes = bytearray(romFile.read())
    bankCount = int(len(romBytes) / 0x4000)
    print (f'Total 16K ROM banks: {bankCount}')
    for bank in range (0, int(bankCount)):
        print ('Bank {0}: 0x{1:04X}'.format(bank + 1, (crc16(romBytes, bank * 0x4000, 0x3fc0))))

if __name__ == "__main__":
    main(sys.argv[1:])