echo Building Spectranet Test ROM module...
sjasmplus testmodule1.sjasm  --lst=testmodule1.lst --lstlab
if [ $? -eq 0 ]; then
    sjasmplus testmodule2.sjasm  --lst=testmodule2.lst --lstlab
    if [ $? -eq 0 ]; then
        echo Building installer...
        sjasmplus installer.sjasm  --lst=installer.lst --lstlab 
            if [ $? -eq 0 ]; then
            echo Building tape image...
            bin2tap -a 32768 -b -c 32767 -o installer.tap installer.bin
        fi
    fi    
fi
exit $?
