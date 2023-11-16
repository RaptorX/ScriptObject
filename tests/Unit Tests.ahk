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

				script.Update(
					"https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver",
					"https://github.com/RaptorX/WindowSnipping/releases/download/latest/WindowSnipping.zip")

				Sleep 1000 ; external update script takes a moment to copy the files
				Yunit.Assert(FileExist("WindowSnipping.ahk"))
			}

			test2_UpdateFalse()
			{
				script := ScriptObj()
				script.version := "1.32.0"

				try script.Update("https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver",
				              "https://github.com/RaptorX/WindowSnipping/releases/download/latest/WindowSnipping.zip")

				catch
					Yunit.Assert(true)
			}

			static CleanUp() {
				FileDelete "WindowSnipping.ahk"
				for dir in ["lib", "res"]
					DirDelete dir, true
			}
		}
	}
}