echo Building main test...
sjasmplus testrammain.sjasm  --lst=testrammain.lst --lstlab
if [ $? -eq 0 ]; then
    echo Building bootstrap...
    sjasmplus testram.sjasm  --lst=testram.lst --lstlab
    if [ $? -eq 0 ]; then
        echo Creating tape image...
        bin2tap -a 24500 -o testram_main.tap testram.bin
        cat testram_loader.tap testram_main.tap > testram.tap
        echo Build complete.
        cp testram.bin bin
        cp testram.tap bin
        echo Binaries copied to bin directory.
    fi
fi
exit $?
