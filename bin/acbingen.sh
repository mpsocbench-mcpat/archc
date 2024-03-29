#!/bin/sh


#
# command line parsing
#
me=`echo "$0" | sed -e 's,.*/,,'`

usage="\
Usage: $0 [options] <model-file>

Create binary utilities source files and optionally build them.

Options:
  -a<name>   sets the architecture name (if ommitted, it defaults to 
             <model-file> without the extension)
  -i<dir>    build and install the binary utilities in directory <dir>
             NOTE: <dir> -MUST- be an absolute path
  -c         only create the files, do not copy to binutils tree
  -f         force patching binutils and gdb tree even if an architecture
             with the same name already exists
  -h         print this help
  -v         print version number

Report bugs and patches to ArchC Team."

version="\
ArchC binutils generator script version 2.2"

help="
Try \`$me -h for more information."

ARCH_NAME=""
CREATE_ONLY=0
BINUTILS_INST_DIR=""
PATCH_BINUTILS=1  #1 means to patch, 0 otherwise
PATCH_GDB=1  #1 means to patch, 0 otherwise
FORCE_PATCH=0 
TEMP_DIR="acbingenbuilddir"

# Parse command line
while getopts  ":hvfca:i:" flag
do
  case $flag in
    h) echo "$usage"; exit 0 ;;
    v) echo "$version" ; exit 0 ;;
    c) CREATE_ONLY=1 ;;
    f) FORCE_PATCH=1 ;;
    a) ARCH_NAME="$OPTARG" ;;
    i) BINUTILS_INST_DIR="$OPTARG" ;;
    *) echo "$me: invalid option $help"
       exit 1 ;;
  esac
done
shift $(($OPTIND - 1))

case $# in
 0 ) echo "No model file specified"
     exit 1 ;;
 1 ) MODEL_FILE=$1 ;;
 * ) echo "Too many arguments"
     exit 1;;
esac

if [ ! -f $MODEL_FILE ]; then
  echo "File does not exist: $MODEL_FILE"
  exit 1
fi

if [ -z "$ARCH_NAME" ]; then
  ARCH_NAME=`echo "$MODEL_FILE" | sed -e "s/\..*$//"`
fi

ARCH_INVALID_CHAR=`echo "$2" | sed -e 's/[a-zA-Z][_a-zA-Z0-9]*//'`

if [ ! -z "$ARCH_INVALID_CHAR" ]; then
  echo "Invalid architecture name: ${ARCH_NAME}"  
  echo "Valid characters include letters, numbers and underscore (only"\
       "letters can begin a name)."
  exit 1
fi

if [ -z "$BINUTILS_PATH" ]; then
  BINUTILS_PATH=`grep BINUTILS_PATH /home/liana/repository/development/MPSoCBench/tools/archc/etc/archc.conf | cut -d = -f2`
  BINUTILS_PATH=`echo $BINUTILS_PATH`
  
#  if [ -z "$BINUTILS_PATH" ]; then
#    echo "BINUTILS_PATH environment variable not set"
#    exit 1
#  fi 
fi


# check for '/' at the end and take it out
BINUTILS_DIR=`echo "$BINUTILS_PATH" | sed -e 's/\/$//'`


FILES_TO_PATCH="bfd/archures.c bfd/Makefile.in bfd/bfd-in2.h bfd/config.bfd bfd/configure bfd/targets.c config.sub gas/configure.tgt gas/Makefile.in opcodes/configure opcodes/Makefile.in opcodes/disassemble.c ld/configure.tgt ld/Makefile.in include/dis-asm.h" 
FILES_TO_COPY="gas/config/tc-xxxxx.c gas/config/tc-xxxxx.h opcodes/xxxxx-opc.c opcodes/xxxxx-dis.c include/opcode/xxxxx.h include/elf/xxxxx.h bfd/elf32-xxxxx.c bfd/cpu-xxxxx.c ld/emulparams/xxxxxelf.sh include/share-xxxxx.h bfd/share-xxxxx.c "

if [ ! -z ${BINUTILS_DIR} ]; then
  if [ "$CREATE_ONLY" -eq 0 ]; then
# tell the user if the architecture name already exists in Binutils
    $BINUTILS_DIR/config.sub ${ARCH_NAME}-elf > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    if [ $FORCE_PATCH -eq 0 ]; then
      echo "==================="
      echo "It has been detected that your Binutils distribution already uses"
      echo "the architecture name '${ARCH_NAME}'."
      echo
      echo "It is not recommended to continue if you have not set it by yourself."
#     echo "If you continue, the Binutils files will not be patched."
      echo "==================="
      echo
      read -p "Do you wish to continue? (y) -> " USER_ANSWER; : ${USER_ANSWER:="y"}
      echo
      case $USER_ANSWER in 
	  y | yes | Y | YES) PATCH_BINUTILS=0; break;;
	  * ) echo "Quitting ..."; echo; exit 1;;
      esac
    else
      PATCH_BINUTILS=0;
    fi
  fi
  fi
fi

# creates binutils directory tree (if none was built)
mkdir -p $TEMP_DIR
[ $? -ne 0 ] && exit $?
cp -rf /home/liana/repository/development/MPSoCBench/tools/archc/share/archc/binutils ${TEMP_DIR}/


# generate the files in the binutils tree
echo "Generating machine dependent code..."
/home/liana/repository/development/MPSoCBench/tools/archc/bin/bmdsfg $MODEL_FILE -a${ARCH_NAME}
[ $? -ne 0 ] && exit $?

cd $TEMP_DIR

# copy 'modifiers' file into the directory
if [ -f ../modifiers ]; then
  cp -f ../modifiers .
else
  touch modifiers
fi

# copy 'dynamic_info.ac' file into the directory
if [ -f ../dynamic_info.ac ]; then
  cp -f ../dynamic_info.ac .
else
  touch dynamic_info.ac
fi

# copy 'dynamic_patch.ac' file into the directory
if [ -f ../dynamic_patch.ac ]; then
  cp -f ../dynamic_patch.ac .
else
  touch dynamic_patch.ac
fi

# copy 'defines_gdb' file into the directory
if [ -f ../defines_gdb ]; then
  cp -f ../defines_gdb .
else
  touch defines_gdb
fi

# change the name of template files
m4 -P defines.m4 binutils/ld/emulparams/xxxxxelf.sh > binutils/ld/emulparams/${ARCH_NAME}elf.sh
m4 -P defines.m4 binutils/include/opcode/xxxxx.h > binutils/include/opcode/${ARCH_NAME}.h
m4 -P defines.m4 binutils/bfd/cpu-xxxxx.c > binutils/bfd/cpu-${ARCH_NAME}.c
m4 -P defines.m4 binutils/gas/config/tc-xxxxx.h > binutils/gas/config/tc-${ARCH_NAME}.h
m4 -P defines.m4 binutils/opcodes/xxxxx-opc.c > binutils/opcodes/${ARCH_NAME}-opc.c
m4 -P defines.m4 binutils/opcodes/xxxxx-dis.c > binutils/opcodes/${ARCH_NAME}-dis.c
m4 -P defines.m4 binutils/include/elf/xxxxx.h > binutils/include/elf/${ARCH_NAME}.h
m4 -P defines.m4 binutils/bfd/elf32-xxxxx.c > binutils/bfd/elf32-${ARCH_NAME}.c
m4 -P defines.m4 binutils/gas/config/tc-xxxxx.c > binutils/gas/config/tc-${ARCH_NAME}.c
m4 -P defines.m4 binutils/include/share-xxxxx.h > binutils/include/share-${ARCH_NAME}.h
m4 -P defines.m4 binutils/bfd/share-xxxxx.c > binutils/bfd/share-${ARCH_NAME}.c

# Check if 'modifiers' is syntatically valid
# ATTENTION: sync with bfd/share-xxxxx.c
if [ -f ../modifiers ]; then
  echo "#include \"binutils/include/share-"${ARCH_NAME}".h\"" > temp_mod.c
  echo "#define ac_modifier_encode(modifier) void modifier_ ##modifier ## _encode(mod_parms *reloc)" >> temp_mod.c
  echo "#define ac_modifier_decode(modifier) void modifier_ ##modifier ## _decode(mod_parms *reloc)" >> temp_mod.c
  echo "#include \"../modifiers\"" >> temp_mod.c
  gcc -c -otemp_mod.o temp_mod.c
  [ $? -ne 0 ] && exit $?
  rm -f temp_mod.o temp_mod.c
fi

if [ "$CREATE_ONLY" -ne 0 ]; then
  echo "Done. No files copied."
  echo
  exit 0
fi


if [ -z "$GDB_PATH" ]; then
  GDB_PATH=`grep GDB_PATH /home/liana/repository/development/MPSoCBench/tools/archc/etc/archc.conf | cut -d = -f2`
  GDB_PATH=`echo $GDB_PATH`
  
  if [ -z "$GDB_PATH" -a -z "$BINUTILS_PATH" ]; then
    echo "Neither BINUTILS_PATH nor GDB_PATH environment variables are set"
    exit 1
  fi 
fi


# check for '/' at the end and take it out
GDB_DIR=`echo "$GDB_PATH" | sed -e 's/\/$//'`

if [ ! -z ${GDB_DIR} ]; then
  FILES_TO_PATCH_GDB="bfd/archures.c bfd/Makefile.in bfd/bfd-in2.h bfd/config.bfd bfd/configure bfd/targets.c config.sub gdb/configure.host gdb/configure.tgt gdb/Makefile.in opcodes/configure opcodes/Makefile.in opcodes/disassemble.c include/dis-asm.h" 
  FILES_TO_COPY_GDB="gdb/xxxxx-tdep.c gdb/config/xxxxx/xxxxx.mt opcodes/xxxxx-opc.c opcodes/xxxxx-dis.c include/opcode/xxxxx.h include/elf/xxxxx.h bfd/elf32-xxxxx.c bfd/cpu-xxxxx.c include/share-xxxxx.h bfd/share-xxxxx.c "

  if [ "$CREATE_ONLY" -eq 0 ]; then
  # tell the user if the architecture name already exists in Gdb
    $GDB_DIR/config.sub ${ARCH_NAME}-elf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      if [ $FORCE_PATCH -eq 0 ]; then
	echo "==================="
	echo "It has been detected that your Gdb distribution already uses"
	echo "the architecture name '${ARCH_NAME}'."
	echo
	echo "It is not recommended to continue if you have not set it by yourself."
#       echo "If you continue, the Gdb files will not be patched."
	echo "==================="
	echo
	read -p "Do you wish to continue? (y) -> " USER_ANSWER; : ${USER_ANSWER:="y"}
	echo
	case $USER_ANSWER in 
	    y | yes | Y | YES) PATCH_GDB=0; break;;
	    * ) echo "Quitting ..."; echo; exit 1;;
	esac
      else
	PATCH_GDB=0;
      fi
    fi
  fi
fi

# creates gdb directory tree (if none was built)
cd ..
TEMP_DIR="acbingenbuilddir"
mkdir -p $TEMP_DIR
[ $? -ne 0 ] && exit $?
cp -rf /home/liana/repository/development/MPSoCBench/tools/archc/share/archc/gdb ${TEMP_DIR}/


# generate the files in the gdb tree
echo "Generating machine dependent code..."
/home/liana/repository/development/MPSoCBench/tools/archc/bin/bmdsfg $MODEL_FILE -a${ARCH_NAME}
[ $? -ne 0 ] && exit $?

cd $TEMP_DIR
mkdir -p gdb/gdb/config/${ARCH_NAME}

# change the name of template files
m4 -P defines.m4 gdb/include/opcode/xxxxx.h > gdb/include/opcode/${ARCH_NAME}.h
m4 -P defines.m4 gdb/bfd/cpu-xxxxx.c > gdb/bfd/cpu-${ARCH_NAME}.c
m4 -P defines.m4 gdb/opcodes/xxxxx-opc.c > gdb/opcodes/${ARCH_NAME}-opc.c
m4 -P defines.m4 gdb/opcodes/xxxxx-dis.c > gdb/opcodes/${ARCH_NAME}-dis.c
m4 -P defines.m4 gdb/include/elf/xxxxx.h > gdb/include/elf/${ARCH_NAME}.h
m4 -P defines.m4 gdb/bfd/elf32-xxxxx.c > gdb/bfd/elf32-${ARCH_NAME}.c
m4 -P defines.m4 gdb/gdb/xxxxx-tdep.c > gdb/gdb/${ARCH_NAME}-tdep.c
m4 -P defines.m4 gdb/gdb/config/xxxxx/xxxxx.mt > gdb/gdb/config/${ARCH_NAME}/${ARCH_NAME}.mt
m4 -P defines.m4 gdb/include/share-xxxxx.h > gdb/include/share-${ARCH_NAME}.h
m4 -P defines.m4 gdb/bfd/share-xxxxx.c > gdb/bfd/share-${ARCH_NAME}.c


if [ "$CREATE_ONLY" -ne 0 ]; then
  echo "Done. No files copied."
  echo
  exit 0
fi


if [ ! -z ${BINUTILS_DIR} ]; then
  if [ "$PATCH_BINUTILS" -ne 0 ]; then
# applies the patch 
    echo "Patching... "
    for file in $FILES_TO_PATCH
    do
      
      if [ ! -f "$BINUTILS_DIR/$file" ]; then

	    if [ $file = "gas/configure.tgt" ]; then
	      # Starting from 2.16, binutils uses configure.tgt
	      # For compatibility with older versions, redirect to 'configure'
	      file="gas/configure"
	      cp -f binutils/gas/configure.tgt.sed binutils/gas/configure.sed > /dev/null 2>&1
	    else           	  
  	      echo "Source file $file not found."
  	      exit 1
        fi
      fi

  # creates a backup
      mv -f $BINUTILS_DIR/$file $BINUTILS_DIR/$file.bkp > /dev/null 2>&1
      if [ $? -ne 0 ]; then
	  echo "Cannot move file $file."
	  exit 1
      fi

      sed s/xxxxx/${ARCH_NAME}/g binutils/$file.sed > binutils/$file.sed2
      sed -f binutils/$file.sed2 $BINUTILS_DIR/$file.bkp > $BINUTILS_DIR/$file

    done
   
    chmod a+x $BINUTILS_DIR/config.sub
    chmod a+x $BINUTILS_DIR/bfd/config.bfd
  else
    echo "Skipping patching..."
  fi

  # copies the generated files into binutils tree
  echo "Copying files to binutils source tree..."
  for file in $FILES_TO_COPY
  do
    cpfile=`echo "$file" | sed -e "s/xxxxx/${ARCH_NAME}/g"`
    cp -f binutils/${cpfile} $BINUTILS_DIR/${cpfile}
    [ $? -ne 0 ] && exit $?
  done

# Checks for newer versions of binutils, which requires archc generated source code changes
# Checking whether write.c uses md_apply_fix or md_apply_fix3
  grep -e "md_apply_fix3" $BINUTILS_DIR/gas/write.c > /dev/null 2>&1
  if [ $? -ne 0 ]; then
  # Newer binutils detected, changing from md_apply_fix3 to md_apply_fix
    sed s/md_apply_fix3/md_apply_fix/g $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.c > $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.c2
    mv $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.c2 $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.c
  fi
# Checking whether expr.c uses md_parse_name(x,y,z) or md_parse_name(x,y,t,z)
  grep -e 'md_parse_name *([^,]*,[^,]*,[^,]*,.*)' $BINUTILS_DIR/gas/expr.c > /dev/null 2>&1
  if [ $? -eq 0 ]; then
  # Newer binutils detected, changing md_parse_name macro to ignore the third parameter
    sed -e 's/define md_parse_name(x, y, z)/define md_parse_name(x, y, t, z)/g' $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.h > $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.h2
    mv $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.h2 $BINUTILS_DIR/gas/config/tc-${ARCH_NAME}.h
  fi

# Checking if BFD requires definition of reloc_name_lookup (binutils 2.18 or higher)
  grep -re "bfd_elfNN_bfd_reloc_name_lookup" $BINUTILS_DIR/bfd/* > /dev/null 2>&1
  if [ $? -eq 0 ]; then
  # BFD requires this definition
    sed -e 's/BFD_REQUIRES_RELOC_NAME_LOOKUP/1/g' $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c > $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c2
    mv $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c2 $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c
  else
  # BFD does not require this definition
    sed -e 's/BFD_REQUIRES_RELOC_NAME_LOOKUP/0/g' $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c > $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c2
    mv $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c2 $BINUTILS_DIR/bfd/elf32-${ARCH_NAME}.c
  fi

fi

if [ ! -z ${GDB_DIR} ]; then
  if [ "$PATCH_GDB" -ne 0 ]; then
  # applies the patch 
      echo "Patching... "
      for file in $FILES_TO_PATCH_GDB
      do
      
        if [ ! -f "$GDB_DIR/$file" ]; then

	      if [ $file = "gdb/configure.tgt" ]; then
  	        # Starting from 2.16, gdb uses configure.tgt
	        # For compatibility with older versions, redirect to 'configure'
	        file="gdb/configure"
	        cp -f gdb/gdb/configure.tgt.sed gdb/gdb/configure.sed > /dev/null 2>&1
	      else           	  
      	        echo "Source file $file not found."
  	        exit 1
          fi
        fi

    # creates a backup
        mv -f $GDB_DIR/$file $GDB_DIR/$file.bkp > /dev/null 2>&1
        if [ $? -ne 0 ]; then
	    echo "Cannot move file $file."
	    exit 1
        fi

        sed s/xxxxx/${ARCH_NAME}/g gdb/$file.sed > gdb/$file.sed2
        sed -f gdb/$file.sed2 $GDB_DIR/$file.bkp > $GDB_DIR/$file
  
      done
   
      chmod a+x $GDB_DIR/config.sub
      chmod a+x $GDB_DIR/bfd/config.bfd

  else
      echo "Skipping patching..."
  fi

  # copies the generated files into gdb tree
  mkdir -p $GDB_DIR/gdb/config/${ARCH_NAME}
  echo "Copying files to gdb source tree..."
  for file in $FILES_TO_COPY_GDB
  do
    cpfile=`echo "$file" | sed -e "s/xxxxx/${ARCH_NAME}/g"`
    cp -f gdb/${cpfile} $GDB_DIR/${cpfile}
    [ $? -ne 0 ] && exit $?
  done
fi


if [ ! -z ${BINUTILS_INST_DIR} ]; then
  echo "Installing the binary utilities..."
 
  if [ ! -z ${BINUTILS_DIR} ]; then
    mkdir -p build
    cd build
    $BINUTILS_DIR/configure --target=${ARCH_NAME}-elf --prefix=`pwd` --bindir=${BINUTILS_INST_DIR}
    [ $? -ne 0 ] && exit $?
    make 
    [ $? -ne 0 ] && exit $?
    make install
    [ $? -ne 0 ] && exit $?
  fi

  if [ ! -z ${GDB_DIR} ]; then
    cd ..
    mkdir -p build_gdb
    cd build_gdb
    $GDB_DIR/configure --target=${ARCH_NAME}-elf --prefix=`pwd` --bindir=${BINUTILS_INST_DIR}
    [ $? -ne 0 ] && exit $?
    make 
    [ $? -ne 0 ] && exit $?
    make install
    [ $? -ne 0 ] && exit $?
  fi

fi

echo "All done successfully."
echo

