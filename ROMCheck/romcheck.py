#
#   Utility to perform CRC-16/CCITT checksumming against a provided
#   ZX Spectrum ROM image, and optinally match it to a list of known
#   ROM image types.
#
#   TODO: Autogenerate this list from romtables.asm
#
#   Brendan Alford, 3rd January 2024.
#
import sys

romChecksumData = [
    ('Spectrum 48K ROM', 0x44e2, 0x0000),
    ('Prototype 48K ROM', 0xfb67, 0x0000),
    ('Spectrum 48K Spanish ROM', 0x5eb1, 0x0000),
    ('Spectrum 128K UK ROM', 0x62c7, 0xbe09, 0x0000),
    ('Spectrum +2 (Grey) ROM', 0xdbaa, 0x27f9, 0x0000),
    ('Spectrum 128k Spanish ROM (v1)', 0xe157, 0x8413, 0x0000),
    ('Spectrum 128k Spanish ROM (v2)', 0x7a1f, 0x8413, 0x0000),
    ('Spectrum +2 (Grey) Spanish ROM', 0xc563, 0xadbb, 0x0000),
    ('Spectrum +2 (Grey) French ROM', 0xda64, 0x9a23, 0x0000),
    ('Spectrum +2A (v4.1) ROM', 0x26f5, 0x4d5b, 0xb3e4, 0x5d75, 0x0000),
    ('Spectrum +3 (v4.0) ROM', 0x1f83, 0x4e7b, 0x3388, 0x5d75, 0x0000),
    ('Spectrum +2A/+3 (v4.0) Spanish ROM', 0x95b8, 0xba48, 0x05c5, 0xd49d, 0x0000),
    ('Spectrum +2A/+3 (v4.1) Spanish ROM', 0x29c0, 0x89c8, 0xf579, 0x8a84, 0x0000),
    ('Spectrum 128 Derby (v1.4) ROM', 0x5129, 0x8c11, 0x000),
    ('Spectrum 128 Derby (v4.02) ROM', 0xe9f5, 0xbe09, 0x000),
    ('Spectrum +3E (v1.38) ROM', 0xdba9, 0xa8e8, 0xe579, 0x4f34, 0x0000),
    ('Spectrum +3E (v1.38) Spanish ROM', 0x3710, 0xa6d0, 0xff63, 0x8a84, 0x0000),
    ('Spectrum +3E (v1.43) ROM', 0x1d79, 0x7899, 0x8571, 0x4f34, 0x0000),
    ('Spectrum +3E (v1.43) Spanish ROM', 0xf1c0, 0x9035, 0x2876, 0x8a84, 0x0000),
    ('Orel BK-08 ROM', 0x26f0, 0x0000),
    ('Spectrum 48K Beckman ROM', 0x5129, 0x0000),
    ('TK-95 ROM', 0x55b9, 0x0000),
    ('TK-90x (v1) ROM', 0xf9e4, 0x0000),
    ('TK-90x (v2) ROM', 0x6074, 0x0000),
    ('TC2048 ROM', 0xac0c, 0x0000),
    ('TS2068 ROM', 0x3246, 0x0000),
    ('Gosh Wonderful 48K ROM', 0x8116, 0x0000)
]

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
    print ("From zx-diagnostics, Brendan Alford 2024\n")
    if (len(argv) != 1):
        print ("Incorrect number of arguments. Please provide filename of ROM file to checksum")
        exit()
    
    fileName = argv[0]
    try:
        romFile = open(fileName, 'rb')
        romBytes = bytearray(romFile.read())
    except:
        print (f'ERROR: Could not open {fileName}.')
        exit()
    if len(romBytes) % 0x4000 != 0:
        print('ERROR: Image must be a multiple of 16K.')
        exit()

    bankCount = int(len(romBytes) / 0x4000)
    bankCRCValues = [0] * bankCount
    print (f'Total 16K ROM banks: {bankCount}')
    for bank in range (0, int(bankCount)):
        bankCRCValues[bank] = crc16(romBytes, bank * 0x4000, 0x3fc0)
        print (f'Bank {bank + 1}: 0x{bankCRCValues[bank]:04X}')
    
    print ('\nChecking against known ROM checksums...\n')

    romMatch = False
    allBanksMatch = True
    for checksumEntry in romChecksumData:

        if bankCRCValues[0] == checksumEntry[1]:
            print(f'First 16K bank matches {checksumEntry[0]}')
            romMatch = True

            for index in range (1, bankCount):
                if checksumEntry[index + 1] == 0:
                    print('Too many 16K banks found for this image, continuing...')
                    break
                if (bankCRCValues[index] == checksumEntry[index + 1]):
                    print(f'Bank {index + 1} matches')
                else:
                    print(f'Bank {index} mismatch, expected {checksumEntry[index + 1]}, got {bankCRCValues[index]}')
                    allBanksMatch = False

        if romMatch:
            break

    if romMatch and allBanksMatch:
        print(f'All ROM bank checksums match. Image verified as {checksumEntry[0]}.')
    else:
        print('This image is not known to this utility.')


if __name__ == "__main__":
    main(sys.argv[1:])