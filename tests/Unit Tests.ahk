#Requires Autohotkey v2.0-

#Include <v2\Yunit\Yunit>
#Include <v2\Yunit\Window>
#Include <v2\ScriptObject\ScriptObject>

Yunit.Use(YunitWindow).Test(ScriptObjectTest)

class ScriptObjectTest
{
	class PropertyTests
	{
		test1_name()
		{
			script := ScriptObj()
			Yunit.Assert(script.name == "Unit Tests")
		}

		test2_version()
		{
			script := ScriptObj()
			script.version := "1.30.0"
			Yunit.Assert(Type(script.version) = "Array")

		}
	}

	class MethodTests
	{
		class Splash
		{
			test_Splash()
			{
				if ScriptObj.testing
					return

				script := ScriptObj()
				script.Splash(A_MyDocuments "\AutoHotkey\v1\AHK-Toolkit\res\img\AHK-TK_Splash.png")
			}
		}

		class AutoStart
		{
			test1_SetAutoStart()
			{
				script := ScriptObj()
				script.Autostart(true)

				cVal := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				Yunit.Assert(cVal == A_ScriptFullPath)
			}

			test2_RemoveAutoStart()
			{
				script := ScriptObj()
				script.Autostart(false)

				; if the registry cant be read then we know the action above
				; was successful
				try RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test3_InvalidValueString()
			{
				script := ScriptObj()
				try script.Autostart("val")
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test4_InvalidValueNot1Or0()
			{
				script := ScriptObj()
				try script.Autostart(3)
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test5_InvalidValueBlank()
			{
				script := ScriptObj()
				try script.Autostart("")
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test6_InvalidValueObject()
			{
				script := ScriptObj()
				try script.Autostart({})
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test7_InvalidValueArray()
			{
				script := ScriptObj()
				try script.Autostart([])
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test7_InvalidValueMap()
			{
				script := ScriptObj()
				try script.Autostart(Map())
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}
		}

		class Update
		{
			end()
			{
				try FileDelete "WindowSnipping.ahk"
				for dir in ["lib", "res"]
					try DirDelete dir, true
			}

			test1_UpdateTrue()
			{
				script := ScriptObj()
				script.version := "1.31.0"

				updated := script.Update(
					"https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver",
					"https://github.com/RaptorX/WindowSnipping/releases/download/latest/WindowSnipping.zip"
				)

				Sleep 1000 ; external update script takes a moment to copy the files
				Yunit.Assert(updated && FileExist("WindowSnipping.ahk"))
			}

			test2_UpdateFalse()
			{
				script := ScriptObj()
				script.version := "1.32.0"

				updated := script.Update(
					"https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver",
					"https://github.com/RaptorX/WindowSnipping/releases/download/latest/WindowSnipping.zip"
				)
				Yunit.Assert(updated = false && !FileExist("WindowSnipping.ahk"))
			}
		}

		class About
		{

			test1_About()
			{
				static WS_VISIBLE := 0x10000000
				script := {
				        base : ScriptObj(),
				     version : '0.0.0',
				      author : 'RaptorX',
				       email : 'teest@gmail.com',
				     crtdate : '123456798',
				     moddate : '123456789',
				homepagetext : '',
				homepagelink : '',
				  donateLink : 'https://www.paypal.com/donate?hosted_button_id=MBT5HSD9G94N6',
				}
				script.About()
				Yunit.Assert(WinExist('About'), 'the window was not created')
				styles := WinGetStyle('About')
				Yunit.Assert(styles & WS_VISIBLE, 'the window is not visible')
				WinClose('About')
			}
		}
		class Licensing
		{
			test_show_the_gui()
			{
				static WS_VISIBLE := 0x10000000
				script := ScriptObj()
				ScriptObj.GetLicense()

				Yunit.Assert(WinExist('License'), 'the window was not created')
				styles := WinGetStyle('License')
				Yunit.Assert(styles & WS_VISIBLE, 'the window is not visible')
				WinClose('License')
			}
		}
	}
}