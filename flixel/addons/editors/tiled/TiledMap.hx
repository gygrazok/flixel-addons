package flixel.addons.editors.tiled;

import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import haxe.io.Path;
import haxe.xml.Fast;
import openfl.Assets;
using StringTools;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledMap
{
	public var version:String; 
	public var orientation:String;
	
	public var backgroundColor:FlxColor;
	
	public var width:Int;
	public var height:Int; 
	public var tileWidth:Int; 
	public var tileHeight:Int;
	
	public var fullWidth:Int;
	public var fullHeight:Int;
	
	public var properties:TiledPropertySet = new TiledPropertySet();
	
	/**
	 * Use to get a tileset by name
	 */
	public var tilesets:Map<String, TiledTileSet> = new Map<String, TiledTileSet>();
	/**
	 * Use for iterating over tilesets, and for merging tilesets (because order is important)
	 */
	public var tilesetArray:Array<TiledTileSet> = [];
	
	public var layers:Array<TiledLayer> = [];
	
	// Add a "noload" property to your Map Properties.
	// Add comma separated values of tilesets, layers, or object names.
	// These will not be loaded.
	var noLoadHash:Map<String, Bool> = new Map<String, Bool>();
	var layerMap:Map<String, TiledLayer> = new Map<String, TiledLayer>();
	var templateMap:Map<String, TiledTemplate> = new Map<String, TiledTemplate>();
	var rootPath:String;
	
	/**
	 * @param data Either a string or XML object containing the Tiled map data
	 * @param rootPath Path to use as root to resolve any internal file references
	 */
	public function new(data:FlxTiledMapAsset, ?rootPath:String)
	{
		var source:Fast = null;
		
		if (rootPath != null)
			this.rootPath = rootPath;
		
		if (Std.is(data, String))
		{
			if (this.rootPath == null)
				this.rootPath = Path.directory(data) + "/";
			source = new Fast(Xml.parse(Assets.getText(data)));
		}
		else if (Std.is(data, Xml))
		{
			if (this.rootPath == null)
				this.rootPath = "";
			source = new Fast(data);
		}
		
		source = source.node.map;
		
		loadAttributes(source);
		loadProperties(source);
		loadTilesets(source);
		loadLayers(source);
	}
	
	function loadAttributes(source:Fast):Void
	{
		version = (source.att.version != null) ? source.att.version : "unknown";
		orientation = (source.att.orientation != null) ? source.att.orientation : "orthogonal";
		backgroundColor = (source.has.backgroundcolor && source.att.backgroundcolor != null) ?
			FlxColor.fromString(source.att.backgroundcolor) : FlxColor.TRANSPARENT;
		
		width = Std.parseInt(source.att.width);
		height = Std.parseInt(source.att.height);
		tileWidth = Std.parseInt(source.att.tilewidth);
		tileHeight = Std.parseInt(source.att.tileheight);
		
		// Calculate the entire size
		fullWidth = width * tileWidth;
		fullHeight = height * tileHeight;
	}
	
	function loadProperties(source:Fast):Void
	{
		for (node in source.nodes.properties)
		{
			properties.extend(node);
		}
		
		var noLoadStr = properties.get("noload");
		if (noLoadStr != null)
		{
			var noLoadArr = ~/[,;|]/.split(noLoadStr);
			
			for (s in noLoadArr)
			{
				noLoadHash.set(s.trim(), true);
			}
		}
	}
	
	function loadTilesets(source:Fast):Void
	{
		for (node in source.nodes.tileset)
		{
			var name = node.has.name ? node.att.name : "";
			
			if (!noLoadHash.exists(name))
			{
				var ts = new TiledTileSet(node, rootPath);
				tilesets.set(ts.name, ts);
				tilesetArray.push(ts);
			}
		}
	}
	
	function loadLayers(source:Fast):Void
	{
		for (el in source.elements)
		{	
			if (el.has.name && noLoadHash.exists(el.att.name))
				continue;
			
			var layer:TiledLayer = switch (el.name.toLowerCase())
			{
				case "layer": new TiledTileLayer(el, this);
				case "objectgroup": new TiledObjectLayer(el, this);
				case "imagelayer": new TiledImageLayer(el, this);
				case _: null;
			}
			
			if (layer != null)
			{
				layers.push(layer);
				layerMap.set(layer.name, layer);
			}
		}
	}
	
	public function getTileSet(name:String):TiledTileSet {
		if (!tilesets.exists(name)) {
			var ts:TiledTileSet = new TiledTileSet(new Fast(Xml.parse(Assets.getText(rootPath+name))).node.tileset);
			tilesets.set(name,ts);
			tilesetArray.push(ts);
		}
		return tilesets.get(name);
	}
	
	public function getLayer(name:String):TiledLayer
	{	
		return layerMap.get(name);
	}

	public function getOrCreateTemplate(name:String):TiledTemplate {
		if (!templateMap.exists(name)) {
			var template:TiledTemplate = new TiledTemplate(new Fast(Xml.parse(Assets.getText(rootPath+name))),this);
			templateMap.set(name,template);
		}
		return templateMap.get(name);
	}
	
	/**
	 * works only after TiledTileSet has been initialized with an image...
	 */
	public function getGidOwner(gid:Int):TiledTileSet
	{
		for (set in tilesets)
		{
			if (set.hasGid(gid))
			{
				return set;
			}
		}
		
		return null;
	}
}

typedef FlxTiledMapAsset = OneOfTwo<String, Xml>;
