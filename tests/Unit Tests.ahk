#Include <Yunit\Yunit>
#Include <Yunit\Window>
#Include <ScriptObject\ScriptObject>

Yunit.Use(YunitWindow).Test(ScriptObjectTest)

class ScriptObjectTest
{
	class PropertyTests
	{
		Test1_name() {
			script := ScriptObj()
			Yunit.Assert(script.name == "Unit Tests")
		}
	}

	class MethodTests
	{
		Test_Splash() {
			script := ScriptObj()
			script.Splash(A_MyDocuments "\AutoHotkey\v1\AHK-Toolkit\res\img\AHK-TK_Splash.png")
		}
		
		class AutoStart {
			Test1_SetAutoStart() {
				script := ScriptObj()
				script.Autostart(true)

				cVal := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				Yunit.Assert(cVal == A_ScriptFullPath)
			}

			Test2_RemoveAutoStart() {
				script := ScriptObj()
				script.Autostart(false)

				; if the registry cant be read then we know the action above
				; was successful
				try RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", A_ScriptName)
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test3_InvalidValueString() {
				script := ScriptObj()
				try script.Autostart("val")
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test4_InvalidValueNot1Or0() {
				script := ScriptObj()
				try script.Autostart(3)
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test5_InvalidValueBlank() {
				script := ScriptObj()
				try script.Autostart("")
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test6_InvalidValueObject() {
				script := ScriptObj()
				try script.Autostart({})
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test7_InvalidValueArray() {
				script := ScriptObj()
				try script.Autostart([])
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}

			Test7_InvalidValueMap() {
				script := ScriptObj()
				try script.Autostart(Map())
				catch
					Yunit.Assert(true), Exit()

				Yunit.Assert(false)
			}
		}
	}
}