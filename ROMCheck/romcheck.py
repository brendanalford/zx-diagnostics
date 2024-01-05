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
    # 16K Bankable ROMS (Spectrum main rom images)
    ('Spectrum 48K ROM', 0x44e2),
    ('Prototype 48K ROM', 0xfb67),
    ('Spectrum 48K Spanish ROM', 0x5eb1),
    ('Spectrum 128K UK ROM', 0x62c7, 0xbe09),
    ('Spectrum +2 (Grey) ROM', 0xdbaa, 0x27f9),
    ('Spectrum 128k Spanish ROM (v1)', 0xe157, 0x8413),
    ('Spectrum 128k Spanish ROM (v2)', 0x7a1f, 0x8413),
    ('Spectrum +2 (Grey) Spanish ROM', 0xc563, 0xadbb),
    ('Spectrum +2 (Grey) French ROM', 0xda64, 0x9a23),
    ('Spectrum +2A (v4.1) ROM', 0x26f5, 0x4d5b, 0xb3e4, 0x5d75),
    ('Spectrum +3 (v4.0) ROM', 0x1f83, 0x4e7b, 0x3388, 0x4f34),
    ('Spectrum +2A/+3 (v4.0) Spanish ROM', 0x95b8, 0xba48, 0x05c5, 0xd49d),
    ('Spectrum +2A/+3 (v4.1) Spanish ROM', 0x29c0, 0x89c8, 0xf579, 0x8a84),
    ('Spectrum 128 Derby (v1.4) ROM', 0x5129, 0x8c11),
    ('Spectrum 128 Derby (v4.02) ROM', 0xe9f5, 0xbe09),
    ('Spectrum +3E (v1.38) ROM', 0xdba9, 0xa8e8, 0xe579, 0x4f34),
    ('Spectrum +3E (v1.38) Spanish ROM', 0x3710, 0xa6d0, 0xff63, 0x8a84),
    ('Spectrum +3E (v1.43) ROM', 0x1d79, 0x7899, 0x8571, 0x4f34),
    ('Spectrum +3E (v1.43) Spanish ROM', 0xf1c0, 0x9035, 0x2876, 0x8a84),
    ('Orel BK-08 ROM', 0x26f0),
    ('Spectrum 48K Beckman ROM', 0x5129),
    ('TK-95 ROM', 0x55b9),
    ('TK-90x (v1) ROM', 0xf9e4),
    ('TK-90x (v2) ROM', 0x6074),
    ('TC2048 ROM', 0xac0c),
    ('TS2068 ROM', 0x3246),
    ('Gosh Wonderful 48K ROM', 0x8116),
    ('Delta 48K ROM', 0xface),
    ('Inves 48K ROM', 0x719A),

    # 8K ROMS

    ('ZX81 Original (550) ROM', 0xa99c),
    ('ZX81 Kludged (550) ROM', 0x1052),
    ('ZX81 Improved (622) ROM', 0x7d71),
    ('ZX81 Fixed (649) ROM', 0x4316),
    ('Ringo R-470 (ZX81 Clone) ROM', 0x7be7),
    ('Lambda 8300 (ZX81 Clone) ROM', 0xd984),

    ('Sinclair Spectrum Test ROM Cartridge', 0xaf96),
    ('Spectrum +2 (Grey) Factory Test ROM', 0x5bad),

    # 4K ROMS
    ('ZX80 ROM', 0x9d46)
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
    
    romSize = 0x4000

    fileName = argv[0]
    try:
        romFile = open(fileName, 'rb')
        romBytes = bytearray(romFile.read())
    except:
        print (f'ERROR: Could not open {fileName}.')
        exit()

    if len(romBytes) == 0x1000:
        romSize = 0x1000
    elif len(romBytes) == 0x2000:
        romSize = 0x2000
    else:
        if len(romBytes) % romSize != 0:
            print('ERROR: Image must be a multiple of 16K.')
            exit()

    # Calculate the number of banks in the image and compute
    # a checksum for each
    bankCount = int(len(romBytes) / romSize)
    bankCRCValues = [0] * bankCount
    print (f'Total {int(romSize / 0x400)}K ROM banks: {bankCount}')
    
    for bank in range (0, int(bankCount)):
        bankCRCValues[bank] = crc16(romBytes, bank * romSize, romSize - 0x40)
        print (f'Bank {bank + 1} checksum: {bankCRCValues[bank]:04X}')
    
    print ('\nChecking against known ROM checksums...\n')

    romMatch = False
    allBanksMatch = True
    for checksumEntry in romChecksumData:

        # Different number of banks to current image to check against, can't be a match
        if len(bankCRCValues) != len(checksumEntry) - 1:
            continue
        
        if bankCRCValues[0] == checksumEntry[1]:
            print(f'First bank matches {checksumEntry[0]}')
            romMatch = True
            
            # Check all remaining banks to ensure that they match
            for index in range (1, bankCount):
                if (bankCRCValues[index] == checksumEntry[index + 1]):
                    print(f'Bank {index + 1} matches')
                else:
                    print(f'Bank {index + 1} mismatch, expected {checksumEntry[index + 1]:04X}, got {bankCRCValues[index]:04X}')
                    romMatch = False

        # Matched a known checksum set, break out
        if romMatch:
            break

    if romMatch:
        print(f'All ROM bank checksums match. Image verified as {checksumEntry[0]}.')
    else:
        print('This image is not known to this utility.')


if __name__ == "__main__":
    main(sys.argv[1:])