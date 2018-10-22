echo Building Test ROM...
sjasmplus testrommain.sjasm --lst=testrommain.lst --lstlab
if [ $? -eq 0 ]; then
    echo Building Bootstrap...
    sjasmplus testrom.sjasm --lst=testrom.lst --lstlab
    if [ $? -eq 0 ]; then
        rm testrommain.bin
        echo Building tape image...
        bin2tap -a 32768 -o testrom.tap testrom.bin
    fi
fi
