PWD=$(shell pwd)
iOS_MIN_VERSION =  11.0
ARCH_FLAGS      =  -arch arm64
TARGET          =  -target arm64-apple-ios11
PLATFORM        =  iphoneos

SDK_PATH                  = $(shell xcrun --show-sdk-path -sdk $(PLATFORM))
TOOLCHAIN                 = Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM)
Compatible_TOOLCHAIN      = Toolchains/XcodeDefault.xctoolchain/usr/lib/swift-5.0/$(PLATFORM)
TOOLCHAIN_PATH            = $(shell xcode-select --print-path)/$(TOOLCHAIN)
Compatible_TOOLCHAIN_PATH = $(shell xcode-select --print-path)/$(Compatible_TOOLCHAIN)

## SWIFT COMPILER SETUP ##
SWIFT        =  $(shell xcrun -f swift) -frontend -c -color-diagnostics
SWIFT_FLAGS  = -g -Onone $(TARGET) \
               -import-objc-header src/bridgingheader.h \
              -sdk $(SDK_PATH)

## CLANG COMPILER SETUP FOR C ##
CLANG        =  $(shell xcrun -f clang) -c
CLANG_FLAGS  =  $(ARCH_FLAGS) \
              -isysroot  $(SDK_PATH) \
              -mios-version-min=$(iOS_MIN_VERSION) -gfull

## LINKER SETTINGS ##
LD        = $(shell xcrun -f ld) -dead_strip -rpath /usr/lib/swift
LD_FLAGS  =  -syslibroot $(SDK_PATH) \
            -lSystem $(ARCH_FLAGS)  \
            -ios_version_min $(iOS_MIN_VERSION) \
            -no_objc_category_merging  \
			-L $(TOOLCHAIN_PATH) \
            -L $(Compatible_TOOLCHAIN_PATH)

SOURCE = $(notdir $(wildcard src/*.swift))

keychaineditor: compile link sign package removegarbage

compile: decodeSecAccessControl.c $(SOURCE) main.swift

decodeSecAccessControl.c:
	$(CLANG) $(CLANG_FLAGS) src/$@

%.swift:
	$(SWIFT) $(SWIFT_FLAGS) -primary-file src/$@ \
	$(addprefix src/,$(filter-out $@,$(SOURCE))) \
	-module-name keychaineditor -o $*.o -emit-module \
	-emit-module-path $*~partial.swiftmodule

main.swift:
	$(SWIFT) $(SWIFT_FLAGS) -primary-file src/$@ \
	$(addprefix src/,$(filter-out $@,$(SOURCE))) \
	-module-name keychaineditor -o main.o -emit-module \
	-emit-module-path main~partial.swiftmodule

link:
	$(LD) $(LD_FLAGS) *.o -o keychaineditor/tmp/keychaineditor/bin/keychaineditor

sign:
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftCore.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftCoreFoundation.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftCoreGraphics.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftDarwin.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftDispatch.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftFoundation.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftObjectiveC.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftos.dylib keychaineditor/tmp/keychaineditor/lib/
	cp -f $(Compatible_TOOLCHAIN_PATH)/libswiftSwiftOnoneSupport.dylib keychaineditor/tmp/keychaineditor/lib/
	./sign.sh

package:
	dpkg-deb -Zgzip -b keychaineditor

removegarbage:
	rm *.o *.swiftmodule

clean:
	rm -f keychaineditor/tmp/keychaineditor/bin/keychaineditor
	rm -f keychaineditor.deb
