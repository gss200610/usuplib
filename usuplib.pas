unit USupLib;


//
// Pascal Unit Support Library (USupLib)
//
// Collection of procedures and functions for general purpose.
//


{$mode objfpc}
{$H+}


interface


// Text functions
function EncloseDoubleQuote(const s: string): string;       // Enclose a string with double quotes (")
function EncloseSingleQuote(const s: string): string;       // Enclose a string with single quotes (')
function CountOccurences(const SubText: string; const Text: string): Integer;
															// Count the number of a subText in text
function LastCharPos(const S: string; const Chr: char): integer;
															// Find the last position of chr in s
function NumberAlign(v: integer; l: byte): string;			// Align a Number on length l, return as string.


// Date and time functions
function GetCurrentDateTimeMicro(): AnsiString;				// Returns the current date time in format YYYY-MM-DD HH:MM:SS.SSS


// Micelanious functions
function ReadSettingKey(path: AnsiString; section: AnsiString; key: AnsiString): AnsiString;
function GeneratePassword(): String;                        // Generate a new password in format AAAAbbbb9999!
function GetCurrentUser(): AnsiString;						// Get the current user name under Linux



// File and Folder functions
procedure CopyTheFile(fnSource, fnDest: AnsiString);		// Copy file from source to dest.


implementation


uses
	Dos,
	Classes,			// For TFileSteam
	sysutils,
	utextfile;


function GetCurrentUser(): AnsiString;
//
// Get the current user on a Linux system.
//
// Reference: https://forum.lazarus.freepascal.org/index.php?topic=4474.0
//
var
	i: Integer;
    es: AnsiString;
    r: AnsiString;
    p: Integer;
    s: AnsiString;
begin
    s := 'USER=';

    for i := 0 to 80 do
    begin
        es := SysUtils.getEnvironmentString(i);
        p := Pos(s, es); 
        If p > 0 then
        begin
            r := RightStr(es, Length(es) - Length(s));
            Exit(r)
        end; // of if

    end; // end for
end; // of function GetCurrentUser()


function GetCurrentDateTimeMicro(): AnsiString;
//
// Returns the current date time in format YYYY-MM-DD HH:MM:SS.SSS
//
var
	Yr: Word;
	Md: Word;
	Dy: Word;
	Dow: Word;
	Hr: Word;
	Mn: Word; // Minutes, conflicts with
	Sc: Word;
	S100: Word;
begin
	GetDate(Yr, Md, Dy, Dow);
	GetTime(Hr, Mn, Sc, S100);
	result := NumberAlign(Yr, 4) + '-' + 
        NumberAlign(Md, 2) + '-' + 
        NumberAlign(Dy, 2) + ' ' + 
        NumberAlign(Hr, 2) + ':' + 
        NumberAlign(Mn, 2) + ':' + 
        NumberAlign(Sc, 2) + '.' + 
        NumberAlign(S100, 3);
end; // of function GetCurrentDateTimeMicro


function NumberAlign(v: integer; l: byte): string;
//
// 
//  Returns a number v aligned on l chars
// 
//
var
	buff: string;
begin
	buff := StringOfChar('0', l) + IntToStr(v);
	NumberAlign := RightStr(buff, l);
end; // of function NumberAlign



function CountOccurences( const SubText: string; const Text: string): Integer;
//
// https://stackoverflow.com/questions/15294501/how-to-count-number-of-occurrences-of-a-certain-char-in-string
//
begin
  Result := Pos(SubText, Text); 
  if Result > 0 then
    Result := (Length(Text) - Length(StringReplace(Text, SubText, '', [rfReplaceAll]))) div  Length(subtext);
end;  { CountOccurences }


procedure CopyTheFile(fnSource, fnDest: AnsiString);
//
// Copy a file 
//
//		fnSource		Full path of the source
//		fnDest			Full path to the dest.
//
var
    SourceF, DestF: TFileStream;
begin
    SourceF := TFileStream.Create(fnSource, fmOpenRead);
    DestF := TFileStream.Create(fnDest, fmCreate);

    DestF.CopyFrom(SourceF, SourceF.Size);
    
    SourceF.Free;
    DestF.Free;
end; // of procedure CopyTheFile()



function GeneratePassword(): String;
//
//	Generate a new password using chars in S.
//	
//	Format: XXXXxxxx9999!
//
const 
	lowerChar = 'abcdefghijklmnopqrstuvwxyz';
	upperChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	numberChar = '0123456789';
	specialChar = '!@#$%'; 
var 
	CharCount: integer; 
begin 
    result := '';
	// Initialize the random number generator.
	Randomize;
	
	// Get 4 upper chars.
	for CharCount := 1 to 4 do 
		result := result + upperChar[random(length(upperChar)) + 1];
		
	//result := result + '-';

	// Get 4 lower chars.
	for CharCount := 1 to 4 do 
		result := result + lowerChar[random(length(lowerChar)) + 1];

	//result := result + '-';	

	// Get 4 number chars.
	for CharCount := 1 to 4 do 
		result := result + numberChar[random(length(numberChar)) + 1];

    result := result + specialChar[random(length(specialChar)) + 1];
end; // of function GeneratePassword.


function EncloseDoubleQuote(const s: string): string;
//
//	Enclose the string s with double quotes: s > "s".
//
var
	r: string;
begin
	if s[1] <> '"' then
		r := '"' + s
	else
		r := s;
		
	if r[Length(r)] <> '"' then
		r := r + '"';

	EncloseDoubleQuote := r;
end; // of function EncloseDoubleQuote


function EncloseSingleQuote(const s: string): string;
//
//	Enclose the string s with single quotes: s > 's'.
//
var
	r: string;
begin
	if s[1] <> '''' then
		r := '''' + s
	else
		r := s;
		
	if r[Length(r)] <> '''' then
		r := r + '''';

	EncloseSingleQuote := r;
end; // of function EncloseSingleQuote


function LastCharPos(const S: string; const Chr: char): integer;
//
// Return the position of chr in s.
//
// https://stackoverflow.com/questions/5844406/find-the-last-occurrence-of-char-in-a-string 
//
var
	i: Integer;
begin	
	result := 0;
	
	for i := length(S) downto 1 do
    	if S[i] = Chr then
      		Exit(i); // Delphi 2009+ code (Exit with value)
end; // of LastCharPos()



function ReadSettingKey(path: AnsiString; section: AnsiString; key: AnsiString): AnsiString;
//
//	Read a Key from a section from a config (.conf) file.
//
//	[Section]
//	Key1=10
//	Key2=Something
//
//	Usage:
//		WriteLn(ReadSettingKey('file.conf', 'Section', 'Key2'));  > returns 'Something'
//		When not found, returns a empty string.
//		
//	Needs updates for checking, validating data.
//
var
	r: string;					// Return value of this function
	sectionName: string;
	inSection: boolean;
	l: string;					// Line buffer
	conf: CTextFile;			// Class Text File 
begin
	conf := CTextFile.Create(path);
	conf.OpenFileRead();

	r := '';
	sectionName := '['+ section + ']';
	inSection := false;
	repeat
		l := conf.ReadFromFile();
		//WriteLn(inSection, #9, l);
		
		if Pos(sectionName, l) > 0 then
		begin
			//WriteLn('FOUND SECTION: ', sectionName);
			inSection := true;
		end;
		
		if inSection = true then
		
		begin
			//if (Pos(key, l) > 0) then
			// key must start at pos 1
			if (Pos(key, l) = 1) then
			begin
				//WriteLn('Found key ', key, ' found in section ', sectionName);
				r := RightStr(l, Length(l) - Length(key + '='));
				//WriteLn(r);
				Break; // break the loop, r contains now the value of the setting.
			end; // of if 
		end; // of if inSection
		
	until conf.GetEof();
	conf.CloseFile();
	ReadSettingKey := r;
end; // of function ReadSettingKey


end. // of unit usuplib