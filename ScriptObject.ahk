#Requires Autohotkey v1.1.33
;--
;@Ahk2Exe-SetVersion     1.0-alpha.1
;@Ahk2Exe-SetProductName Script Object
;@Ahk2Exe-SetDescription Small library to add similar functionality to all scripts
/**
 * ============================================================================ *
 * @Author           : RaptorX                                                  *
 * @Homepage         :                                                          *
 *                                                                              *
 * @Created          : July 13, 2022                                            *
 * @Modified         : July 26, 2022                                            *
 *                                                                              *
 * @Description      :                                                          *
 * -------------------                                                          *
 * Small library to add similar functionality to all scripts                    *
 * ============================================================================ *
 * License:                                                                     *
 * Copyright ©2022 RaptorX <GPLv3>                                              *
 *                                                                              *
 * This program is free software: you can redistribute it and/or modify         *
 * it under the terms of the **GNU General Public License** as published by     *
 * the Free Software Foundation, either version 3 of the License, or            *
 * (at your option) any later version.                                          *
 *                                                                              *
 * This program is distributed in the hope that it will be useful,              *
 * but **WITHOUT ANY WARRANTY**; without even the implied warranty of           *
 * **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**.  See the        *
 * **GNU General Public License** for more details.                             *
 *                                                                              *
 * You should have received a copy of the **GNU General Public License**        *
 * along with this program. If not, see:                                        *
 * <http://www.gnu.org/licenses/gpl-3.0.txt>                                    *
 * ============================================================================ *
 */

; global script := {base         : script
;                  ,name          : regexreplace(A_ScriptName, "\.\w+")
;                  ,version      : "0.1.0"
;                  ,author       : ""
;                  ,email        : ""
;                  ,crtdate      : ""
;                  ,moddate      : ""
;                  ,homepagetext : ""
;                  ,homepagelink : ""
;                  ,donateLink   : "https://www.paypal.com/donate?hosted_button_id=MBT5HSD9G94N6"
;                  ,resfolder    : A_ScriptDir "\res"
;                  ,iconfile     : A_ScriptDir "\res\sct.ico"
;                  ,configfile   : A_ScriptDir "\settings.ini"
;                  ,configfolder : A_ScriptDir ""}

/**
 * Class: Script
 * 
 * Small library to add similar functionality to all scripts
 */
class Script
{
	static DBG_NONE     := 0
	      ,DBG_ERRORS   := 1
	      ,DBG_WARNINGS := 2
	      ,DBG_VERBOSE  := 3

	static name         := ""
	      ,version      := ""
	      ,author       := ""
	      ,email        := ""
	      ,crtdate      := ""
	      ,moddate      := ""
	      ,homepagetext := ""
	      ,homepagelink := ""
	      ,resfolder    := ""
	      ,icon         := ""
	      ,config       := ""
	      ,systemID     := ""
	      ,dbgFile      := ""
	      ,dbgLevel     := this.DBG_NONE


	/**
		Function: Update
		Checks for the current script version
		Downloads the remote version information
		Compares and automatically downloads the new script file and reloads the script.

		Parameters:
		vfile - Version File
		        Remote version file to be validated against.
		rfile - Remote File
		        Script file to be downloaded and installed if a new version is found.
		        Should be a zip file that will be unzipped by the function

		Notes:
		The versioning file should only contain a version string and nothing else.
		The matching will be performed against a SemVer format and only the three
		major components will be taken into account.

		e.g. '1.0.0'

		For more information about SemVer and its specs click here: <https://semver.org/>
	*/
	Update(vfile, rfile, silent:=true)
	{
		; Error Codes
		static ERR_INVALIDVFILE := 1
		,ERR_INVALIDRFILE       := 2
		,ERR_NOCONNECT          := 3
		,ERR_NORESPONSE         := 4
		,ERR_INVALIDVER         := 5
		,ERR_CURRENTVER         := 6
		,ERR_MSGTIMEOUT         := 7
		,ERR_USRCANCEL          := 8

		; A URL is expected in this parameter, we just perform a basic check
		; TODO make a more robust match
		if (!regexmatch(vfile, "^((?:http(?:s)?|ftp):\/\/)?((?:[a-z0-9_\-]+\.)+.*$)"))
			throw {code: ERR_INVALIDVFILE, msg: "Invalid URL`n`nThe version file parameter must point to a valid URL."}

		; This function expects a ZIP file
		if (!regexmatch(rfile, "\.zip"))
			throw {code: ERR_INVALIDRFILE, msg: "Invalid Zip`n`nThe remote file parameter must point to a zip file."}

		; Check if we are connected to the internet
		http := comobjcreate("WinHttp.WinHttpRequest.5.1")
		http.Open("GET", "https://www.google.com", true)
		http.Send()
		try
			http.WaitForResponse(1)
		catch e
			throw {code: ERR_NOCONNECT, msg: e.message}

		if !silent
			Progress, 50, 50/100, % "Checking for updates", % "Updating"

		; Download remote version file
		http.Open("GET", vfile, true)
		http.Send(), http.WaitForResponse()

		if !(http.responseText)
		{
			Progress, OFF
			throw {code: ERR_NORESPONSE, msg: "There was an error trying to download the ZIP file.`n"
											. "The server did not respond."}
		}

		regexmatch(this.version, "\d+\.\d+(\.\d+)?(-.*)?", loVersion)
		regexmatch(http.responseText, "\d+\.\d+(\.\d+)?(-.*)?", remVersion)

		if !silent
		{
			Progress, 100, 100/100, % "Checking for updates", % "Updating"
			sleep 500 	; allow progress to update
			Progress, OFF
		}

		; Make sure SemVer is used
		if (!loVersion || !remVersion)
			throw {code: ERR_INVALIDVER, msg: "Invalid version.`nThis function works with SemVer. "
											. "For more information refer to the documentation in the function"}

		; Compare against current stated version
		ver1 := strsplit(loVersion, ".")
		ver2 := strsplit(remVersion, ".")

		for i1,num1 in ver1
		{
			for i2,num2 in ver2
			{
				if (newversion)
					break

				if (i1 == i2)
					if (num2 > num1)
					{
						newversion := true
						break
					}
					else
						newversion := false
			}
		}

		if (!newversion)
			throw {code: ERR_CURRENTVER, msg: "You are using the latest version"}
		else
		{
			; If new version ask user what to do
			; Yes/No | Icon Question | System Modal
			msgbox % 0x4 + 0x20 + 0x1000
				 , % "New Update Available"
				 , % "There is a new update available for this application.`n"
				   . "Do you wish to upgrade to v" remVersion "?"
				 , 10	; timeout

			ifmsgbox timeout
				throw {code: ERR_MSGTIMEOUT, msg: "The Message Box timed out."}
			ifmsgbox no
				throw {code: ERR_USRCANCEL, msg: "The user pressed the cancel button."}

			; Create temporal dirs
			ghubname := (InStr(rfile, "github") ? regexreplace(a_scriptname, "\..*$") "-latest\" : "")
			filecreatedir % tmpDir := a_temp "\" regexreplace(a_scriptname, "\..*$")
			filecreatedir % zipDir := tmpDir "\uzip"

			; Create lock file
			fileappend % a_now, % lockFile := tmpDir "\lock"

			; Download zip file
			urldownloadtofile % rfile, % tmpDir "\temp.zip"

			; Extract zip file to temporal folder
			oShell := ComObjCreate("Shell.Application")
			oDir := oShell.NameSpace(zipDir), oZip := oShell.NameSpace(tmpDir "\temp.zip")
			oDir.CopyHere(oZip.Items), oShell := oDir := oZip := ""

			filedelete % tmpDir "\temp.zip"

			/*
			******************************************************
			* Wait for lock file to be released
			* Copy all files to current script directory
			* Cleanup temporal files
			* Run main script
			* EOF
			*******************************************************
			*/
			if (a_iscompiled){
				tmpBatch =
				(Ltrim
					:lock
					if not exist "%lockFile%" goto continue
					timeout /t 10
					goto lock
					:continue

					xcopy "%zipDir%\%ghubname%*.*" "%a_scriptdir%\" /E /C /I /Q /R /K /Y
					if exist "%a_scriptfullpath%" cmd /C "%a_scriptfullpath%"

					cmd /C "rmdir "%tmpDir%" /S /Q"
					exit
				)
				fileappend % tmpBatch, % tmpDir "\update.bat"
				run % a_comspec " /c """ tmpDir "\update.bat""",, hide
			}
			else
			{
				tmpScript =
				(Ltrim
					while (fileExist("%lockFile%"))
						sleep 10

					FileCopyDir %zipDir%\%ghubname%, %a_scriptdir%, true
					FileRemoveDir %tmpDir%, true

					if (fileExist("%a_scriptfullpath%"))
						run %a_scriptfullpath%
					else
						msgbox `% 0x10 + 0x1000
							 , `% "Update Error"
							 , `% "There was an error while running the updated version.``n"
								. "Try to run the program manually."
							 ,  10
						exitapp
				)
				fileappend % tmpScript, % tmpDir "\update.ahk"
				run % a_ahkpath " " tmpDir "\update.ahk"
			}
			filedelete % lockFile
			exitapp
		}
	}

	/**
		Function: Autostart
		This Adds the current script to the autorun section for the current
		user.

		Parameters:
		status - Autostart status
		         It can be either true or false.
		         Setting it to true would add the registry value.
		         Setting it to false would delete an existing registry value.
	*/
	Autostart(status)
	{
		if (status)
		{
			RegWrite, REG_SZ
			        , HKCU\SOFTWARE\microsoft\windows\currentversion\run
			        , %a_scriptname%
			        , %a_scriptfullpath%
		}
		else
			regdelete, HKCU\SOFTWARE\microsoft\windows\currentversion\run
			         , %a_scriptname%
	}

	/**
		Function: Splash
		Shows a custom image as a splash screen with a simple fading animation

		Parameters:
		img   (opt) - file to be displayed
		speed (opt) - fast the fading animation will be. Higher value is faster.
		pause (opt) - long in seconds the image will be paused after fully displayed.
	*/
	Splash(img:="", speed:=10, pause:=2)
	{
		global

		gui, splash: -caption +lastfound +border +alwaysontop +owner
		$hwnd := winexist(), alpha := 0
		winset, transparent, 0

		gui, splash: add, picture, x0 y0 vpicimage, % img
		guicontrolget, picimage, splash:pos
		gui, splash: show, w%picimagew% h%picimageh%

		setbatchlines 3
		loop, 255
		{
			if (alpha >= 255)
				break
			alpha += speed
			winset, transparent, %alpha%
		}

		; pause duration in seconds
		sleep pause * 1000

		loop, 255
		{
			if (alpha <= 0)
				break
			alpha -= speed
			winset, transparent, %alpha%
		}
		setbatchlines -1

		gui, splash:destroy
		return
	}

	/**
		Funtion: Debug
		Allows sending conditional debug messages to the debugger and a log file filtered
		by the current debug level set on the object.

		Parameters:
		level - Debug Level, which can be:
		        * this.DBG_NONE
		        * this.DBG_ERRORS
		        * this.DBG_WARNINGS
		        * this.DBG_VERBOSE

		If you set the level for a particular message to *this.DBG_VERBOSE* this message
		wont be shown when the class debug level is set to lower than that (e.g. *this.DBG_WARNINGS*).

		label - Message label, mainly used to show the name of the function or label that triggered the message
		msg   - Arbitrary message that will be displayed on the debugger or logged to the log file
		vars* - Aditional parameters that whill be shown as passed. Useful to show variable contents to the debugger.

		Notes:
		The point of this function is to have all your debug messages added to your script and filter them out
		by just setting the object's dbgLevel variable once, which in turn would disable some types of messages.
	*/
	Debug(level:=1, label:=">", msg:="", vars*)
	{
		if !this.dbglevel
			return

		for i,var in vars
			varline .= "|" var

		dbgMessage := label ">" msg "`n" varline

		if (level <= this.dbglevel)
			outputdebug % dbgMessage
		if (this.dbgFile)
			FileAppend, % dbgMessage, % this.dbgFile
	}

	/**
		Function: About
		Shows a quick HTML Window based on the object's variable information

		Parameters:
		scriptName   (opt) - Name of the script which will be
		                     shown as the title of the window and the main header
		version      (opt) - Script Version in SimVer format, a "v"
		                     will be added automatically to this value
		author       (opt) - Name of the author of the script
		homepagetext (opt) - Display text for the script website
		homepagelink (opt) - Href link to that points to the scripts
		                     website (for pretty links and utm campaing codes)
		donateLink   (opt) - Link to a donation site
		email        (opt) - Developer email

		Notes:
		The function will try to infer the paramters if they are blank by checking
		the class variables if provided. This allows you to set all information once
		when instatiating the class, and the about GUI will be filled out automatically.
	*/
	About(scriptName:="", version:="", author:="", homepagetext:="", homepagelink:="", donateLink:="", email:="")
	{
		static doc

		scriptName := scriptName ? scriptName : this.name
		version := version ? version : this.version
		author := author ? author : this.author
		homepagetext := homepagetext ? homepagetext : RegExReplace(this.homepagetext, "http(s)?:\/\/")
		homepagelink := homepagelink ? homepagelink : RegExReplace(this.homepagelink, "http(s)?:\/\/")
		donateLink := donateLink ? donateLink : RegExReplace(this.donateLink, "http(s)?:\/\/")
		email := email ? email : this.email

		if (donateLink)
		{
			donateSection =
			(
				<div class="donate">
					<p>If you like this tool please consider <a href="https://%donateLink%">donating</a>.</p>
				</div>
				<hr>
			)
		}

		html =
		(
			<!DOCTYPE html>
			<html lang="en" dir="ltr">
				<head>
					<meta charset="utf-8">
					<meta http-equiv="X-UA-Compatible" content="IE=edge">
					<style media="screen">
						.top {
							text-align:center;
						}
						.top h2 {
							color:#2274A5;
							margin-bottom: 5px;
						}
						.donate {
							color:#E83F6F;
							text-align:center;
							font-weight:bold;
							font-size:small;
							margin: 20px;
						}
						p {
							margin: 0px;
						}
					</style>
				</head>
				<body>
					<div class="top">
						<h2>%scriptName%</h2>
						<p>v%version%</p>
						<hr>
						<p>%author%</p>
						<p><a href="https://%homepagelink%" target="_blank">%homepagetext%</a></p>
					</div>
					%donateSection%
				</body>
			</html>
		)

		btnxPos := 300/2 - 75/2
		axHight := donateLink ? 16 : 12

		gui aboutScript:new, +alwaysontop +toolwindow, % "About " this.name
		gui margin, 0
		gui color, white
		gui add, activex, w300 r%axHight% vdoc, htmlFile
		gui add, button, w75 x%btnxPos% gaboutClose, % "Close"
		doc.write(html)
		gui show
		return

		aboutClose:
			gui aboutScript:destroy
		return
	}

	/*
		Function: GetLicense
		Parameters:
		Notes:
	*/
	GetLicense()
	{
		global

		this.systemID := this.GetSystemID()
		cleanName := RegexReplace(A_ScriptName, "\..*$")
		for i,value in ["Type", "License"]
			RegRead, %value%, % "HKCU\SOFTWARE\" cleanName, % value

		if (!License)
		{
			MsgBox, % 0x4 + 0x20
			      , % "No license"
			      , % "Seems like there is no license activated on this computer.`n"
			        . "Do you have a license that you want to activate now?"

			IfMsgBox, Yes
			{
				Gui, license:new
				Gui, add, Text, w160, % "Paste the License Code here"
				Gui, add, Edit, w160 vLicenseNumber
				Gui, add, Button, w75 vTest, % "Save"
				Gui, add, Button, w75 x+10, % "Cancel"
				Gui, show

				saveFunction := Func("licenseButtonSave").bind(this)
				GuiControl, +g, test, % saveFunction
				Exit
			}

			MsgBox, % 0x30
			      , % "Unable to Run"
			      , % "This program cannot run without a license."

			ExitApp, 1
		}

		return {"type"    : Type
		       ,"number"  : License}
	}

	/*
		Function: SaveLicense
		Parameters:
		Notes:
	*/
	SaveLicense(licenseType, licenseNumber)
	{
		cleanName := RegexReplace(A_ScriptName, "\..*$")

		Try
		{
			RegWrite, % "REG_SZ"
			        , % "HKCU\SOFTWARE\" cleanName
			        , % "Type", % licenseType

			RegWrite, % "REG_SZ"
			        , % "HKCU\SOFTWARE\" cleanName
			        , % "License", % licenseNumber

			return true
		}
		catch
			return false
	}

	/*
		Function: IsLicenceValid
		Parameters:
		Notes:
	*/
	IsLicenceValid(licenseType, licenseNumber, URL)
	{
		res := this.EDDRequest(URL, "check_license", licenseType ,licenseNumber)

		if InStr(res, """license"":""inactive""")
			res := this.EDDRequest(URL, "activate_license", licenseType ,licenseNumber)

		if InStr(res, """license"":""valid""")
			return true
		else
			return false
	}

	GetSystemID()
	{
		wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\cimv2")
		(wmi.ExecQuery("Select * from Win32_BaseBoard")._newEnum)[Computer]
		return Computer.SerialNumber
	}

	/*
		Function: EDDRequest
		Parameters:
		Notes:
	*/
	EDDRequest(URL, Action, licenseType, licenseNumber)
	{
		strQuery := url "?edd_action=" Action
		         .  "&item_id=" licenseType
		         .  "&license=" licenseNumber
		         .  (this.systemID ? "&url=" this.systemID : "")

		try
		{
			http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			http.Open("GET", strQuery)
			http.SetRequestHeader("Pragma", "no-cache")
			http.SetRequestHeader("Cache-Control", "no-cache, no-store")
			http.SetRequestHeader("User-Agent", "Mozilla/4.0 (compatible; Win32)")

			http.Send()
			http.WaitForResponse()

			return http.responseText
		}
		catch err
			return err.what ":`n" err.message
	}

	; Activate()
	; 	{
	; 	strQuery := this.strEddRootUrl . "?edd_action=activate_license&item_id=" . this.strRequestedProductId . "&license=" . this.strEddLicense . "&url=" . this.strUniqueSystemId
	; 	strJSON := Url2Var(strQuery)
	; 	Diag(A_ThisFunc . " strQuery", strQuery, "")
	; 	Diag(A_ThisFunc . " strJSON", strJSON, "")
	; 	return JSON.parse(strJSON)
	; 	}
	; Deactivate()
	; 	{
	; 	Loop, Parse, % "/|", |
	; 	{
	; 	strQuery := this.strEddRootUrl . "?edd_action=deactivate_license&item_id=" . this.strRequestedProductId . "&license=" . this.strEddLicense . "&url=" . this.strUniqueSystemId . A_LoopField
	; 	strJSON := Url2Var(strQuery)
	; 	Diag(A_ThisFunc . " strQuery", strQuery, "")
	; 	Diag(A_ThisFunc . " strJSON", strJSON, "")
	; 	this.oLicense := JSON.parse(strJSON)
	; 	if (this.oLicense.success)
	; 	break
	; 	}
	; 	}
	; GetVersion()
	; 	{
	; 	strQuery := this.strEddRootUrl . "?edd_action=get_version&item_id=" . this.oLicense.item_id . "&license=" . this.strEddLicense . "&url=" . this.strUniqueSystemId
	; 	strJSON := Url2Var(strQuery)
	; 	Diag(A_ThisFunc . " strQuery", strQuery, "")
	; 	Diag(A_ThisFunc . " strJSON", strJSON, "")
	; 	return JSON.parse(strJSON)
	; 	}
	; RenewLink()
	; 	{
	; 	strUrl := this.strEddRootUrl . "checkout/?edd_license_key=" . this.strEddLicense . "&download_id=" . this.oLicense.item_id
	; 	Diag(A_ThisFunc . " strUrl", strUrl, "")
	; 	return strUrl
	; 	}
}

licenseButtonSave(this, CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	GuiControlGet, LicenseNumber
	if this.IsLicenceValid(this.eddID, licenseNumber, "https://www.the-automator.com")
	{
		this.SaveLicense(this.eddID, LicenseNumber)
		MsgBox, % 0x30
		      , % "License Saved"
		      , % "The license was applied correctly!`n"
		        . "The program will start now."
		
		Reload
	}
	else
	{
		MsgBox, % 0x10
		      , % "Invalid License"
		      , % "The license you entered is invalid and cannot be activated."

		ExitApp, 1
	}
}

licenseButtonCancel(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="")
{
	MsgBox, % 0x30
	      , % "Unable to Run"
	      , % "This program cannot run without a license."

	ExitApp, 1
}