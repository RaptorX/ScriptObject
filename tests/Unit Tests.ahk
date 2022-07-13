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
	}

	class MethodTests {
/* 		test_Splash() {
			script := ScriptObj()
			script.Splash(A_MyDocuments "\AutoHotkey\v1\AHK-Toolkit\res\img\AHK-TK_Splash.png")
		}
 */		
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
		class Update {
				Yunit.Assert(false)
			}
		}
	}
}