#!/usr/bin/env python3

import os
import shutil
import subprocess

os.chdir("..")
if os.path.exists("tmp"):
    shutil.rmtree("tmp")
os.mkdir("tmp")
os.chdir("tmp")

modules = ['/Applications/Xcode.app/Contents/SharedFrameworks/SourceEditor.framework/SourceEditor'
          ,'/Applications/Xcode.app/Contents/SharedFrameworks/SourceKit.framework/SourceKit']
with open('list.txt', "w") as f3:
    for module in modules: 
        cmd = 'nm' + ' ' + module
        with open('cmd.txt', "w") as handle:
            subprocess.run(cmd, shell=True, stdout=handle)
        with open('cmd.txt') as handle:
            for line in handle:
                words = line.split()
                for word in words:
                    if len(word) >= 2 and word[0] == '_' and word[1] == '$':
                        cmd2 = "swift demangle '" + word + "'" 
                        with open('cmd2.txt', "w") as handle2:
                            subprocess.run(cmd2, shell=True, stdout=handle2)
                        with open('cmd2.txt') as handle2:
                            for line2 in handle2:
                                #print(line2)
                                f3.write(line2)

