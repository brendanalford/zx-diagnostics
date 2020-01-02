echo Building Spectranet Test ROM module...
sjasmplus romcheck.sjasm  --lst=romcheck.lst --lstlab
if [ $? -eq 0 ]; then
    sjasmplus testmodule2.sjasm  --lst=testmodule2.lst --lstlab
    if [ $? -eq 0 ]; then
        echo Building tape image...
        bin2tap -a 32768 -b -c 32767 -o installer.tap installer.bin
    fi    
fi
exit $?
