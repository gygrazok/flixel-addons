package flixel.addons.editors.tiled;
import haxe.xml.Fast;

class TiledTemplate {
	public var tileset:TiledTileSet;
	public var gid:Int;
	public var type:String;
	public var width:Int;
	public var height:Int;
	public var xmlData:Fast;
	public function new(source:Fast, parent:TiledMap) {
		xmlData = source.node.template;

		tileset = parent.getTileSet(xmlData.node.tileset.att.source);
		gid = Std.parseInt(xmlData.node.object.att.gid);
		type = (xmlData.node.object.has.type)?xmlData.node.object.att.type:"";
		width = Std.parseInt(xmlData.node.object.att.width);
		height = Std.parseInt(xmlData.node.object.att.height);
	}
	
	public function applyProperties(properties:TiledPropertySet) {
		for (node in xmlData.nodes.properties) {
			properties.extend(node);
		}
	}
}