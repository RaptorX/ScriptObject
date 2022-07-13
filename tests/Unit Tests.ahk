#Include <Yunit\Yunit>
#Include <Yunit\Window>
#Include <ScriptObject\ScriptObject>

Yunit.Use(YunitWindow).Test(ScriptObjectTest)

class ScriptObjectTest
{
	class PropertyTests
	{
		Test1_name(){
			script := {base: ScriptObj()}
			Yunit.Assert(script.name == "Unit Tests")
		}
	}
}