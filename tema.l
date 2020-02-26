/* Borcea Rares Ioan Grupa 334CC */

%{
#include <iostream>
#include <fstream>
#include <cstdio>
#include <cstdlib>
#include <list>
#include <string>
#include <unordered_map>
#include <cstring>

using namespace std;

// Structure for strings list
typedef struct {
  string line;		// Line to be printed to output
  int indent;		// Line indentation in output
} strings;

// Structure for tags hashmap
typedef struct {
  int currIndex;	// Currently used index for tag list
  int startPos;		// Position in strings list
} tags;

int depth = 0;		// Current depth in XML tree
int listPos = 0;	// Current position in strings list

// Tags hashmap and Strings list
unordered_map<string, tags> tagTypes;
list<strings> toPrint;

// Auxiliary strings used for processing
string tagWithValue;
string attrib;

// Previously opened and closed tags
string prevClosedTag;
string prevOpenedTag;

// Add tag type to map and string line to print list
void addTag(string tagToCheck) {
	if (prevClosedTag.compare(tagToCheck) != 0) {
		// Different type of tag than previous
		// Add tag to tagType map
		tags newTag;
		newTag.currIndex = 0;
		newTag.startPos = listPos++;
		tagTypes.insert({tagToCheck, newTag});

		// Check if prev tag was a list
		if (!prevClosedTag.empty()) {
			auto findTag = tagTypes.find(prevClosedTag);
			if (findTag != tagTypes.end()) {
				// If true, then reduce depth - that list is over
				if (findTag->second.currIndex != 0) {
					depth--;
				}
				// and erase the list from tagType map
				tagTypes.erase(findTag);
			}	
		}

		// Add line to toPrint strings list
		strings lineToPrint;
		string stringLine("<" + tagToCheck + ">");
		lineToPrint.line = stringLine;
		lineToPrint.indent = depth;
		toPrint.push_back(lineToPrint);

		// Update previously opened tag with current one
		prevOpenedTag = tagToCheck;
		
	} else {

		// Same type of tag - we have a list
		auto findTag = tagTypes.find(prevClosedTag);

		// Erase prevClosedTag - otherwise, we could mistake
		// children tags as same-level tags and end list
		prevClosedTag = "";

		// Check if this is the second element of the list
		if (findTag->second.currIndex == 0) {
			// If it is, we have to introduce the ZERO index
			// Advance to first elem and precede it by '<0>''
			list<strings>::iterator it = toPrint.begin(); 
			advance(it, findTag->second.startPos);
			if (it != toPrint.end()) {
			    it++;
			}
			depth++;
			string indexLine("<0>");
			strings indexLineToPrint;
			indexLineToPrint.line = indexLine;
			indexLineToPrint.indent = depth;
			toPrint.insert(it, indexLineToPrint);
			listPos++;

			// Update depth of all following lines
			for (it; it != toPrint.end(); it++) {
				(it->indent)++;
			}

			// Insert index for current elem
			string newIndexLine("<1>");
			strings newIndexLineToPrint;
			newIndexLineToPrint.line = newIndexLine;
			newIndexLineToPrint.indent = depth;
			toPrint.push_back(newIndexLineToPrint);

			// Update current index in list in hashmap
			(findTag->second.currIndex)++;
			listPos++;

		} else {

			// Part of an already opened list
			// Update current index in list in hashmap
			(findTag->second.currIndex)++;

			// Add curent index in toPrint strings list
			string indexLine("<" + to_string(findTag->second.currIndex) + ">");
			strings indexLineToPrint;
			indexLineToPrint.line = indexLine;
			indexLineToPrint.indent = depth;
			toPrint.push_back(indexLineToPrint);
			listPos++;
		}
	}
}
%}

%option noyywrap
 
tag [_a-zA-Z][-_a-zA-Z.0-9]*
attribute [^\n \"><]*
value [^\n\"><]*

%x IN_COMMENT XML_PROLOG ATTRIBUTES

%%

<INITIAL>{
			"<?xml"				BEGIN(XML_PROLOG);

			"<!--"				BEGIN(IN_COMMENT);

			"<"{tag}" "			{
								// Tag with attributes
								// Increase depth
								depth++;

								// Add tag to structures
								char *tagName = (char*)malloc(sizeof(char) * (yyleng - 1));
								strcpy(tagName, yytext + 1);
								tagName[yyleng - 2] = '\0';
								string tagToCheck(tagName);
								addTag(tagToCheck);

								// Increase depth and add attributes
								depth++;
								BEGIN(ATTRIBUTES);
								}

			"<"{tag}">"/"\n"	{
								// Tag without attributes
								// Increase depth
								depth++;

								// Add tag to structures
								char *tagName = (char*)malloc(sizeof(char) * (yyleng - 1));
								strcpy(tagName, yytext + 1);
								tagName[yyleng - 2] = '\0';
								string tagToCheck(tagName);
								addTag(tagToCheck);
								}

			"<"{tag}">"/{value}	{
								// Tag with direct value
								// Check if there was a previous list
								if (!prevClosedTag.empty()) {
									// If true, then reduce depth and erase list from map
									auto findTag = tagTypes.find(prevClosedTag);
									if (findTag != tagTypes.end()) {
										if (findTag->second.currIndex != 0) {
											depth--;
										}
										tagTypes.erase(findTag);
									}	
								}

								// Increase depth
								depth++;

								// Create string to be completed with value
								char *tagName = (char*)malloc(sizeof(char) * (yyleng - 1));
								strcpy(tagName, yytext + 1);
								tagName[yyleng - 2] = '\0';
								tagWithValue = tagName;

								// Mark as previously opened tag
								prevOpenedTag = tagWithValue;
								tagWithValue = tagWithValue + " : ";
								}

			{value}				{
								// Direct value of previously opened tag
								// Complete line and add it to toPrint strings list
								tagWithValue = tagWithValue + string(yytext);
								string toAdd(tagWithValue);
								strings valueToAdd;
								valueToAdd.line = toAdd;
								valueToAdd.indent = depth;
								toPrint.push_back(valueToAdd);
								listPos++;
								}
			
			"</"{tag}">"		{
								// Closing tag which could have been a list
								// Check if it was a list
								if (!prevClosedTag.empty()) {
									auto findTag = tagTypes.find(prevClosedTag);
									if (findTag != tagTypes.end()) {
										// If true, then reduce depth and erase list from map
										if (findTag->second.currIndex != 0) {
											depth--;
										}
										tagTypes.erase(findTag);
									}	
								}

								// Decrease depth after closing tag
								depth--;

								// Mark as prevClosedTag
								char *tagName = (char*)malloc(sizeof(char) * (yyleng - 2));
								strcpy(tagName, yytext + 2);
								tagName[yyleng - 3] = '\0';
								prevClosedTag = tagName;
								}

			"/>"				{
								// Closing tag which couldn't have been a list
								// Decrease depth after closing tag
								depth--;

								// Mark as prevClosedTag, based on prevOpenedTag
								prevClosedTag = prevOpenedTag;
								}

			\n					// Eat newlines
			}

<XML_PROLOG>{
			"?>"|"?>\n"			BEGIN(INITIAL); 
			.|\n				// Eat prolog in chunks
			}

<IN_COMMENT>{
			"-->"|"-->\n"		BEGIN(INITIAL); 
			.|\n				// Eat comment in chunks
			}

<ATTRIBUTES>{
			{tag}/"="			{
								// Attribute, store name preceded by '_'
								attrib = "_" + string(yytext) + " : ";
								}

			"=\""{attribute}	{
								// Attribute value, complete line and add to toPrint
								string toAdd = attrib;
								toAdd = toAdd + string(yytext + 2);
								strings attribToAdd;
								attribToAdd.line = toAdd;
								attribToAdd.indent = depth;
								toPrint.push_back(attribToAdd);
								listPos++;
								}

			"\">"				{
								// End of attributes
								depth -= 1;
								BEGIN(INITIAL);	
								}

			"\">"{value}		{
								// Attribute, followed by direct value
								// Precede by '__text' and add to toPrint strings list
								string toAdd("__text : ");
								toAdd = toAdd + string(yytext + 2);
								strings textToAdd;
								textToAdd.line = toAdd;
								textToAdd.indent = depth;
								toPrint.push_back(textToAdd);
								listPos++;
								}

			"\" "				// Eat space between attributes

			"</"{tag}">"		{
								// Closing of tag with attributes
								// Mark as prevClosedTag
								char *tagName = (char*)malloc(sizeof(char) * (yyleng - 2));
								strcpy(tagName, yytext + 2);
								tagName[yyleng - 3] = '\0';
								prevClosedTag = tagName;

								// Decrease depth by 2 - one for attrib, one for tag itself
								depth -= 2;

								BEGIN(INITIAL);	
								}

			"\"/>"				{
								// Closing of empty tag
								// Mark as prevClosedTag based on prevOpenedTag
								prevClosedTag = prevOpenedTag;

								// Decrease depth by 2 - one for attrib, one for tag itself
								depth -= 2;

								BEGIN(INITIAL);	
								}						
			}

%%

// Driver function
int main(int argc, char *argv[]) {

	// Start analyzer on input file
	yyin = fopen(argv[1], "r");
	if (!yyin) {
		printf("Error opening input file. Exiting."); 
		exit(1);
	}
	yylex();

	// Print output to output file
	ofstream output("output.txt");

	if (output.is_open()) {
		// Print 'root' tag first
		output << "<root>" << endl;

		// Print toPrint strings list, considering indentation
		for (list<strings>::iterator it = toPrint.begin(); it != toPrint.end(); it++) {
			for (int i = 0; i < it->indent; i++) {
				output << '\t';
			}
			output << it->line << endl;
		}

		output.close();
	} else {
		cout << "Error opening output file. Exiting.";
		exit(1);
	} 

	return 0;
}