#This probably wont work on your computer
#Use command+B in Xcode instead
all: game_engine3 default.metallib

SWIFT_SC=gameObject.swift ContentView.swift AppDelegate.swift Renderer.swift

#Where ever Xcode decided to store the app
#You need to change this
PATH=/Users/apple1/Library/Developer/Xcode/DerivedData/game_engine3-enjevanikxzcexgmiraiawszwfbp/Build/Products/Debug/game_engine3.app/Contents/

#./shader_types is a module that allows swift to link with ShaderTypes.h
FLAGS=-suppress-warnings -I./shader_types

#compile the CPU code
game_engine3: $(SWIFT_SC) ShaderTypes.h game_engine3-Bridging-Header.h makefile
	swiftc $(FLAGS) $(SWIFT_SC) -o game_engine3
	cp game_engine3 $(PATH)/MacOS

#compile the shaders
default.metallib: Shaders.metal ShaderTypes.h makefile
	metal -w Shaders.metal
	cp default.metallib $(PATH)/Resources
	
clean:
	rm game_engine3 default.metallib

#runs the app
run: all
	$(PATH)/MacOS/game_engine3

#same as command+B except the output is in ../build
xc:
	zsh -c 'cd .. && /usr/bin/xcodebuild ;'
	
