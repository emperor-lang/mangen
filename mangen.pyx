#!/usr/bin/python3

import json
import jsonschema
import sys
import re
from cpython cimport bool

schemaFile:str = '../argspec/user-arguments-schema.json'

def printe(*args, **kwargs) -> None:
	print(*args, file=sys.stderr, **kwargs)

cdef class Program:
	cdef str title
	cdef str shortDescription
	cdef str longDescription
	cdef str licence
	cdef str version
	cdef str date
	cdef list seeAlso
	cdef str bugs
	cdef str author
	cdef list args
	cdef list examples
	cdef bool autoGenerateSynopsis

	def __cinit__(self, program:dict) -> None:
		self.title = program['program'] # Mandatory 
		self.args = program['args'] # Mandatory
		self.args.sort(key=lambda arg:arg['short'].lower() if 'short' in arg else arg['long'].upper())
		self.shortDescription = self.formatGroff(program['description'])	if 'description' in program else			None
		self.longDescription = self.formatGroff(program['longDescription'])	if 'longDescription' in program else		None
		self.licence = program['licence']									if 'licence' in program else 				None
		self.version = program['version']									if 'version' in program else				None
		self.date = program['date']											if 'date' in program else 					''
		self.seeAlso = program['seeAlso']									if 'seeAlso' in program else				[]
		self.bugs = self.formatGroff(program['bugs'])						if 'bugs' in program else					None
		self.author = self.formatGroff(program['author'])					if 'author' in program else					None
		self.examples = program['examples']									if 'examples' in program else				[]
		self.autoGenerateSynopsis = program['autoGenerateSynopsis']			if 'autoGenerateSynopsis' in program else	True

	cdef str formatGroff(self, inputString:str):
		# Rudamendary MD to roff converter---THIS IS REGULAR NOT CONTEXT FREE!
		inputLines:[str] = inputString.split('\n')
		for i in range(len(inputLines)):
			inputLines[i] = inputLines[i].strip()
			inputLines[i] = (re.sub(r'`([^\s`]*)`', r'\\fB\1\\fP', inputLines[i]))
			inputLines[i] = (re.sub(r'(\s|\(|\)|\|)_([^_]*)_(\s|\(|\)|\|)', r'\1\\fI\2\\fP\3', inputLines[i]))
			inputLines[i] = (re.sub(r'(\s|\(|\)|\|)\*\*([^\*]*)\*\*(\s|\(|\)|\|)', r'\1\\fB\2\\fP\3', inputLines[i]))
		return '\n.PP\n'.join(inputLines)

	def __dealloc__(self) -> None:
		pass
		# del self.title
		# del self.shortDescription
		# del self.longDescription
		# del self.licence
		# del self.version
		# del self.date
		# del self.seeAlso
		# del self.bugs
		# del self.about
		# del self.args
		# del self.examples

	def __str__(self) -> str:
		return self.toString()

	cdef str toString(self):
		toReturn:[str] = []
		
		# Prepare the licence
		if self.licence is not None:
			licenceStr:str = '.\\" ' + '\n.\\" '.join(self.licence.split('\n'))
			toReturn.append(licenceStr)

		# Prepare the header
		programVersion:str = self.title
		if self.version is not None:
			programVersion += f' {self.version}'
		header:str = f'.TH "{self.title.upper()}" "1" "{self.date}" "{programVersion}" "User Commands"'
		toReturn.append(header)

		# Prepare description
		if self.shortDescription is not None:
			# Make the first letter lowercase
			shortDesc:str = self.shortDescription[0].lower()
			if len(self.shortDescription) > 1:
				shortDesc += self.shortDescription[1:]
			programDescription:str = f'\\fB{self.title}\\fP - {shortDesc}'
			toReturn.append(f'.SH "NAME"')
			toReturn.append(programDescription)

		# Prepare synopsis
		synopsis:[str] = []
		if self.examples != [] or (self.autoGenerateSynopsis and self.args != []):
			toReturn.append('.SH SYNOPSIS')
		# Automatically from arguments
		if self.autoGenerateSynopsis and self.args != []:
			# Generate a synopsis
			synopsisParts:[str] = [f'\\fB{self.title}\\fP']
			self.args.sort(key=lambda arg:arg['mandatory'])
			for argument in self.args:
				argumentString:str = argument['short'] if 'short' in argument else argument['long']
				synopsisParts.append(f"[\\fB{argumentString}\\fP]")
			synopsis.append(' '.join(synopsisParts))
		# From examples
		if self.examples != []:
			# Use specified synopsis
			for example in self.examples:
				exampleParts:[str] = example['input'].split(' ')
				synopsisString:str = f'\\fB{exampleParts[0]}\\fP'
				for examplePart in exampleParts[1:]:
					synopsisString += ' '
					inOption:bool = False
					for char in examplePart:
						if not inOption:
							if char == '-':
								synopsisString += r'\fB'
								inOption = True
							synopsisString += char
						else:
							if char == ']' or char == '|':
								synopsisString += r'\fP'
								inOption = False
								synopsisString += char
							elif char == '=':
								synopsisString += char + r'\fP'
								inOption = False
							else:
								synopsisString += char
				synopsis.append(synopsisString)
		if synopsis != []:
			toReturn.append('\n.br\n'.join(synopsis))
		
		# Prepare arguments
		if self.args != []:
			toReturn.append('.SH OPTIONS')
			for arg in self.args:
				argumentString:str = '.TP\n'
				argumentForms:[str] = []
				formKeys:[str] = (['short'] if 'short' in arg else []) + (['long'] if 'long' in arg else [])
				choicesString:str = None
				if 'choices' in arg:
					choicesString = '{' + ','.join(arg['choices']) + '}'
				for form in formKeys:
					argumentForm:str = f'\\fB{arg[form]}\\fP'
					if choicesString is not None:	
						argumentForm += ' ' + choicesString
					argumentForms.append(argumentForm)
				argumentString += ', '.join(argumentForms) + '\n' + self.formatGroff(arg['help'])
				toReturn.append(argumentString)

		# Prepare longer description
		if self.longDescription is not None:
			toReturn.append('.SH DESCRIPTION')
			toReturn.append(self.longDescription)

		# Prepare the see-alsos
		if self.seeAlso != []:
			toReturn.append('.SH "SEE ALSO"')
			toReturn.append(', '.join([f'\\fB{toSee["name"]}\\fP({toSee["manLocation"]})' for toSee in self.seeAlso]))

		# Prepare the bugs
		if self.bugs is not None:
			toReturn.append('.SH BUGS')
			toReturn.append(self.bugs)

		# Prepare the author
		if self.author is not None:
			toReturn.append('.SH AUTHOR')
			toReturn.append(self.author)

		return '\n'.join(toReturn)

def main(args:[str]) -> int:
	spec:dict
	try:
		spec = json.load(sys.stdin)
	except json.decoder.JSONDecodeError as jsonde:
		printe(str(jsonde) + f' while handling json from stdin')
		return -1

	schema:dict
	with open(schemaFile, 'r+') as i:
		try:
			schema = json.load(i)
		except json.decoder.JSONDecodeError as jsonde:
			printe(str(jsonde) + f' while handling schema in "{schemaFile}"')
			return -1

	try:
		jsonschema.validate(instance=spec, schema=schema)
	except jsonschema.exceptions.ValidationError as ve:
		printe(f'Input specification did not match the schema (using schema: "{schemaFile}"')
		printe(str(ve))
		return -1

	program:Program = Program(spec)
	sys.stdout.write(str(program))
	sys.stdout.write('\n')

if __name__ == '__main__':
	sys.exit(main(sys.argv[1:]))