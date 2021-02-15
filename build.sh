echo ========================
echo Building Diagboard stuff
echo ========================
./builddiag.sh
if [ $? -eq 0 ]; then 
    echo =================
    echo Building Main ROM
    echo =================
    git rev-parse --abbrev-ref HEAD > branch.txt
    git rev-parse --short HEAD > commit.txt
    /bin/hostname > hostname.txt
    ./buildmain.sh
    if [ $? -eq 0 ]; then
        cd FlashUtils
        echo ======================
        echo Building FLASH Utility
        echo ======================
        ./build.sh
        if [ $? -eq 0 ]; then
            cd ../TestTape
            echo =========================
            echo Building tape based tests
            echo =========================
            ./build.sh
            if [ $? -eq 0 ]; then
                cd ../Spectranet
                echo ================================
                echo Building Spectranet test modules
                echo ================================
                ./build.sh
                if [ $? -eq 0 ]; then
                    cd ../ROMCheck
                    echo ============================
                    echo Building ROM Checker utility
                    echo ============================
                    ./build.sh
                    if [ $? -eq 0 ]; then
                        cd ..
                        echo All builds complete
                        exit
                    fi
                fi
            fi
        fi
    fi
fi
echo Aborting main build.
