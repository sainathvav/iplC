
#include "scanner.hh"
#include "parser.tab.hh"
#include <fstream>
#include <string>
#include <vector>
using namespace std;

SymbTab gst, gstfun, gststruct; 
string filename;
extern std::map<std::string, abstract_astnode*> ast;
vector<string> instructions;
vector<string> metadata;
int instr_count = 0;
vector<string> registers;
int stack_top_offset = 0;


int main(int argc, char **argv)
{
	registers.push_back("%eax");
	registers.push_back("%ebx");
	registers.push_back("%ecx");
	registers.push_back("%edx");
	registers.push_back("%esi");
	registers.push_back("%edi");

	// stack_top_offset -= 24;

	using namespace std;
	fstream in_file, out_file;
	

	in_file.open(argv[1], ios::in);

	IPL::Scanner scanner(in_file);

	IPL::Parser parser(scanner);

	#ifdef YYDEBUG
		parser.set_debug_level(1);
	#endif
	parser.parse();

	string filename = argv[1];
	
	cout << "\t.file \"" + filename + "\"" << endl;

	for (int i = 0; i < metadata.size(); i++) {
		int len = metadata[i].length();
		if (metadata[i][len-1] != ':') {
			cout << "\t";
		}
		cout << metadata[i] << endl;
	}
	
	for (int i = 0; i < instructions.size(); i++) {
		int len = instructions[i].length();
		if (instructions[i][len - 1] != ':') {
			cout << "\t";
		}
		cout << instructions[i] << endl;
	}

	cout << "\t.ident	\"GCC: (Ubuntu 8.1.0-9ubuntu1~16.04.york1) 8.1.0\"" << endl;
	cout << "\t.section	.note.GNU-stack,\"\",@progbits" << endl;
	fclose(stdout);
}
