import argparse
from datetime import date
import json
import sys
import os.path
import argparse

class TroffArgumentParser(object):
	def __init__(self, json:dict=None, licence:[str]=[], version:str=None, seeAlso:[str]=[], date:str=date.today().strftime('%d %B %Y'), bugs:str=None, *args, **kwargs):
		super(TroffArgumentParser, self).__init__(*args, **kwargs)
		self.prog = json['prog'] if json is not None and 'prog' in json else ''
		self.description = json['description'] if json is not None and 'description' in json else '' 
		self.licence = json['licence'] if json is not None and 'licence' in json else licence
		self.version = json['version'] if json is not None and 'version' in json else version
		self.date = json['date'] if json is not None and 'date' in json else date
		self.seeAlso = json['seeAlso'] if json is not None and 'seeAlso' in json else seeAlso
		self.bugs = json['bugs'] if json is not None and 'bugs' in json else bugs
		self._actions:[argparse.Action] = json['actions'] if json is not None and 'actions' in json else []
		self.epilog = json['epilog'] if json is not None and 'epilog' in json else None

	def toTroff(self) -> str:
		options:[argparse.Action] = self._actions
		options.sort(key=lambda option : option['required'])

		troffOutput:str = self._header(self.prog, self.date, self.version, self.licence)
		troffOutput += self._name(self.prog, self.description)
		troffOutput += self._synopsis(self.prog, options)
		troffOutput += self._description(self.description)
		troffOutput += self._options(options)
		troffOutput += self._seeAlso(self.seeAlso)
		troffOutput += self._bugs(self.bugs)
		troffOutput += self._authors(self.epilog)
		return troffOutput

	def _header(self, program:str, date:str, version:str, licence:[str]) -> str:
		licenceString:str
		if licence != []:
			licenceString = ''.join(list(map(lambda line: r'.\" ' + line, licence))) + '\n'
		else:
			licenceString = ''
		programVersion:str = f'{program} {version}' if version is not None else program
		return f'{licenceString}.TH {program.upper()} 1 "{date}" "{programVersion}" "User Commands" "fdsa"\n'

	def _name(self, prog:str, description:str) -> str:
		return f'.SH "NAME"\n\\fB{prog}\\fP - {description}\n'

	def _synopsis(self, prog:str, options:[argparse.Action]) -> str:
		return f'.SH "SYNOPSIS"\n\\fB{prog}\\fP [OPTION]... [file... | -]\n'

	def _description(self, description:str) -> str:
		if description != '':
			return f'.SH "DESCRIPTION"\n{description}\n'
		else:
			return ''

	def _options(self, options:[argparse.Action]) -> str:
		if options == []:
			return ''
		else:
			description:str = f'.SH "OPTIONS"'
			firstOption:bool = True
			previousWasMandatory:bool = False
			mandatory:bool = False
			for option in options:
				mandatory = option['required']
				if firstOption:
					if mandatory:
						description += f'\n.SS "Mandatory arguments"'
					else:
						description += f'\n.SS "Optional arguments"'
				elif mandatory and not previousWasMandatory:
					description += f'\n.SS "Mandatory arguments"'
					doingMandatory = True
				# 	switchToPrintingMandatoryOptions = False
				# if not self._checkMandatory(option):
				# 	switchToPrintingMandatoryOptions = True
				optionString:str = self._formatList(option['option_strings']) if option['option_strings'] != [] else option['metavar']
				optionString = r'\fB' + optionString + r'\fP '
				if option['choices'] is not None:
					choices:str = self._formatList(option['choices'], separator=',')
					optionString += r'\fI{' + choices + r'}\fP'
				elif option['nargs'] is None:
					optionString += r'\fI' + (option['metavar'].upper() if option['metavar'] is not None else option['dest'].upper()) + r'\fP'
					pass
				elif option['nargs'] == '*':
					pass
				elif option['nargs'] == '+':
					pass
				elif int(option['nargs']) >= 0:
					pass

				optionHelp:str = option['help']
				optionDescription:str = f'\n.TP\n{optionString}\n{optionHelp}'
				description += optionDescription
				firstOption = False
				previousWasMandatory = option['required']
			return description + '\n'

	def _formatList(self, lst:[str], separator:str=', ') -> str:
		formattedList:str = ''
		if lst is not None:
			formattedList = ''
			firstItem:bool = True
			for item in lst:
				if not firstItem:
					formattedList += separator
				firstItem = False
				formattedList += item
		return formattedList

	def _seeAlso(self, seeAlso:[str]) -> str:
		if seeAlso == []:
			return ''
		else:
			# seeAlso = list(map(lambda see: '('.join(see.split('(')), seeAlso))
			for i in range(len(seeAlso)):
				split:[str] = seeAlso[i].split('(')
				see:str = split[0]
				sec:str = split[1].replace(')', '')
				seeAlso[i] = f'\\fB{see}\\fR({sec})'
			seeAlsos:str = ', '.join(seeAlso)
			return f'.SH "SEE ALSO"\n{seeAlsos}\n'

	def _bugs(self, bugs:str) -> str:
		return f'.SH "BUGS"\n{bugs}\n' if bugs is not None else ''

	def _authors(self, epilog:str) -> str:
		return f'.SH "AUTHOR"\n{epilog}\n' if epilog is not None else ''


def printe(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)


def parseArguments(args:[str]) -> argparse.Namespace:
	parser: argparse.ArgumentParser = argparse.ArgumentParser()

	parser.add_argument('-?', action='help', help='Show this help message and exit')
	parser.add_argument('-', '--stdin', dest='useStdin', action='store_true', help='Use stdin', default=False)
	parser.add_argument('-i', '--input_file', dest='inputFile', help='Input json spec', default=None)
	parser.add_argument('-o', '--output_file', dest='outputFile', help='Man-page output file', default=sys.stdout)

	if len(args) == 0:
		parser.print_usage(sys.stderr)
	
	return parser.parse_args(args)

def main(args:[str]) -> int:
	arguments:argparse.Namespace = parseArguments(args)

	inputString:str
	if arguments.useStdin:
		inputString = input()
	else:
		if arguments.inputFile is not None:
			if os.path.isfile(arguments.inputFile):
				with open(arguments.inputFile, 'r+') as i:
					inputString = i.read()
			else:
				printe(f'File "{arguments.inputFile}" does not exist')
				return 126
		else:
			printe('Please specify an input file')
			return 1

	try:
		jsonReturn:object = json.loads(inputString)
		if type(jsonReturn) != dict:
			printe(f'Got JSON of type "{type(jsonReturn).__name__}", expected a dictionary')
			return 1
		jsonDict:dict = jsonReturn
	except json.decoder.JSONDecodeError as jsonDe:
		printe('Could not decode JSON input')
		printe(jsonDe)
		return 1

	troffArgumentParser:TroffArgumentParser = TroffArgumentParser(json=jsonDict)

	# Output
	outputString:str = troffArgumentParser.toTroff()
	if arguments.outputFile == sys.stdout:
		print(outputString, end='')
	else:
		with open(arguments.outputFile, 'w+') as o:
			o.write(outputString)

	return 0

if __name__ == '__main__':
	sys.exit(main(sys.argv[1:]))