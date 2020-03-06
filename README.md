# XML_Parser
XML Parser, built using FLEX - The Fast Lexical Analyzer, in C++

The program analyzes each line and stores, in a linked list, the formatted output to be printed. Considering that a continuous sequence of the same type of tags should form an indexed list, the position in the to-be-printed list of the first element of each type is stored in a HashMap, together with the current index in that respective tag-type list. In the event of a sequence, the ZERO index will be inserted before the first element, indentation will be increased by one TAB, the rest of the list being added successively.
