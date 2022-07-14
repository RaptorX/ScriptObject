#Requires Autohotkey v2.0-

#Include <Yunit\Yunit>
#Include <Yunit\Window>
#Include <ScriptObject\ScriptObject>

Yunit.Use(YunitWindow).Test(ScriptObjectTest)

class ScriptObjectTest {
	class PropertyTests {
		test1_name() {
			script := ScriptObj()
			Yunit.Assert(script.name == "Unit Tests")
		}

		test2_version() {
			script := ScriptObj()
			script.version := "1.30.0"
			Yunit.Assert(Type(script.version) = "Array")

		}
	}

	class MethodTests {

		class Splash {
			test_Splash() {
				if ScriptObj.testing
					return

				script := ScriptObj()
				script.Splash(A_MyDocuments "\AutoHotkey\v1\AHK-Toolkit\res\img\AHK-TK_Splash.png")
			}
		}

		class AutoStart {
			test1_SetAutoStart() {
				script := ScriptObj()
				script.Autostart(true)

				cVal := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				Yunit.Assert(cVal == A_ScriptFullPath)
			}

			test2_RemoveAutoStart() {
				script := ScriptObj()
				script.Autostart(false)

				; if the registry cant be read then we know the action above
				; was successful
				try RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test3_InvalidValueString() {
				script := ScriptObj()
				try script.Autostart("val")
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test4_InvalidValueNot1Or0() {
				script := ScriptObj()
				try script.Autostart(3)
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test5_InvalidValueBlank() {
				script := ScriptObj()
				try script.Autostart("")
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test6_InvalidValueObject() {
				script := ScriptObj()
				try script.Autostart({})
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test7_InvalidValueArray() {
				script := ScriptObj()
				try script.Autostart([])
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}

			test7_InvalidValueMap() {
				script := ScriptObj()
				try script.Autostart(Map())
				catch
					return Yunit.Assert(true)

				Yunit.Assert(false)
			}
		}

		class Update {
			test1_CheckConnection() {
				res := ScriptObj.isConnectedToInternet()
				Yunit.Assert(InStr(res, "<!doctype html>"))
			}

			test2_GetUpcomingVersion() {
				verFile := "https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver"

				upcomingVer := ScriptObj.GetUpcomingVersion(verFile)
				for vNum in ["1","32","0"]
					if upcomingVer[A_Index] != vNum
						Yunit.Assert(false)
			}

			test3_CheckNewVersionTrue() {
				script := ScriptObj()
				script.version := "1.31.0"

				verFile := "https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver"
				upcomingVer := ScriptObj.GetUpcomingVersion(verFile)
				if ScriptObj.isNewVersionAvailable(script.version, upcomingVer)
					Yunit.Assert(true)
				else
					Yunit.Assert(false)

			}

			test4_CheckNewVersionFalse() {
				script := ScriptObj()
				script.version := "1.32.0"

				verFile := "https://raw.githubusercontent.com/RaptorX/WindowSnipping/master/ver"
				upcomingVer := ScriptObj.GetUpcomingVersion(verFile)
				if !ScriptObj.isNewVersionAvailable(script.version, upcomingVer)
					Yunit.Assert(true)
				else
					Yunit.Assert(false)

			}

			test5_InstallNewVersion() {
				if FileExist("WindowSnipping.ahk")
					return ScriptObjectTest.MethodTests.Update.CleanUp()

				ScriptObj.InstallNewVersion("https://github.com/RaptorX/WindowSnipping/releases/download/latest/WindowSnipping.zip")

				Sleep 1000 ; external update script takes a moment to copy the files
				Yunit.Assert(FileExist("WindowSnipping.ahk"))

				ScriptObjectTest.MethodTests.Update.CleanUp()
			}


			static CleanUp() {
				FileDelete "WindowSnipping.ahk"
				for dir in ["lib", "res"]
					DirDelete dir, true
			}
		}
	}
}