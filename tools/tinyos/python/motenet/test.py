#!/usr/bin/env python3

import pdb

class Simple():
    def __init__(self, name):
        self.name = name

    def hello(self):
        print(self.name + " says hi.")

class Simple2(Simple):
    pass


if __name__ == '__main__':
    pdb.set_trace()
    x = Simple('roger')
    x.hello()

    x = Simple2('tom')
    x.hello()
