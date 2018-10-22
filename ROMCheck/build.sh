echo Building ROMCheck program...
sjasmplus romcheck.sjasm  --lst=romcheck.lst --lstlab
if [ $? -eq 0 ]; then
    echo Building tape image...
    bin2tap -a 25000 -o romcheck_main.tap romcheck.bin
    cat romcheck_loader.tap romcheck_main.tap > romcheck.tap
fi
exit $?
