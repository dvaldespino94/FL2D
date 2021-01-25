import std.json;
import std.format;
import std.stdio;
import std.conv;
import std.stdint;
import std.file;
import std.algorithm.iteration;

import fltk_d;

/**
 * UIItem
 */
class UIItem
{
    UIItem[] items;

    bool anon = false;
    string decl_code="";

    bool active = true;
    bool resizable = false;

    int alignment = 0;

    string name;
    string widget_type;
    string parent;

    int type;
    long x, y, w, h;
    string label;

    long[] box;
    long[] colors;
    long[] labelinfo;

    this(JSONValue item)
    {
        this.widget_type = item["widget_type"].str.asClassName;

        if (this.widget_type=="decl"){
            this.decl_code=item["decl"].str;
            return;
        }

        this.name = item["name"].str;

        assert(this.name != "");

        this.anon = this.name.length > 8 && this.name[0 .. 8] == "tempname";

        this.x = item["xywh"].array[0].integer;
        this.y = item["xywh"].array[1].integer;
        this.w = item["xywh"].array[2].integer;
        this.h = item["xywh"].array[3].integer;
        this.type=cast(int)item["type"].integer;
        this.active = cast(bool)("active" in item) && (item["active"].integer);
        this.resizable = cast(bool)(("resizable" in item) && item["resizable"].boolean);

        item["box"].array.each!(x => box ~= box_from_name(x.str));
        item["colors"].array.each!(x => colors ~= x.integer);
        item["labelinfo"].array.each!(x => labelinfo ~= x.integer);

        this.alignment = cast(int) item["align"].integer;
        this.label = item["label"].str;
        this.parent = item["parent"].str;
    }

    string decl()
    {
        if (this.widget_type=="decl")
            return this.decl_code;
        string ret;
        if (!this.anon)
            ret = format("%s %s;", this.widget_type, this.name);
        foreach (item; items)
        {
            ret ~= item.decl() ~ "\n";
        }
        return ret;
    }

    string generate()
    {
        if (this.widget_type=="decl")
            return "";

        string ret = "";

        if (this.anon)
            ret = format("%s %s=new %s(%d,%d,%d,%d,\"%s\"); //@%s\n", this.widget_type,
                    this.name, this.widget_type, this.x, this.y, this.w, this.h, this.label, this.parent);
        else
            ret = format("%s=new %s(%d,%d,%d,%d,\"%s\"); //@%s\n", this.name,
                    this.widget_type, this.x, this.y, this.w, this.h, this.label, this.parent);

        ret ~= format("%s._align=%d;\n", this.name, this.alignment);

        if (this.box[0] != 0)
            ret ~= format("%s.box=cast(Boxtype)%d; //%s\n", this.name,
                    this.box[0], box_names[cast(uint)this.box[0]]);

        ret ~= format("%s.color=%d;\n", this.name, this.colors[0]);

        ret ~= format("%s.color2=%d;\n", this.name, this.colors[1]);

        ret ~= format("%s.selection_color=%d;\n", this.name, this.colors[2]);

        if (this.resizable)
        {
            ret ~= format("%s.parent().resizable(%s);", this.name, this.name);
        }

        if (this.widget_type == "Button")
        {
            ret ~= format("%s.down_color=%d;\n", this.name, this.colors[3]);
            ret ~= format("%s.down_box=cast(Boxtype)%d; //%s\n", this.name,
                    this.box[1], box_names[cast(uint)this.box[1]]);
        }

        if (!this.active)
            ret ~= format("%s.deactivate();\n", this.name);

        if (this.labelinfo[0] != 0)
            ret ~= format("%s.labelcolor=%d;\n", this.name, this.labelinfo[0]);
        if (this.labelinfo[1] != 0)
            ret ~= format("%s.labelfont=%d;\n", this.name, this.labelinfo[1]);
        if (this.labelinfo[2] != 14)
            ret ~= format("%s.labelsize=%d;\n", this.name, this.labelinfo[2]);
        if (this.labelinfo[3] != 0)
            ret ~= format("%s.labeltype=cast(Labeltype)%d;\n", this.name, this.labelinfo[3]);

        if (items.length > 0)
        {
            ret ~= "{";
            ret ~= format("scope(exit) %s.end();", this.name);
            foreach (item; items)
            {
                ret ~= item.generate;
            }

            
            ret ~= "}";
        }

        return ret;
    }

    override string toString()
    {
        string ret = format("%s/%s (%s)", this.parent, this.name, this.widget_type);
        foreach (child; items)
        {
            ret ~= "\n" ~ child.toString;
        }
        ret ~= "\n";

        return ret;
    }
}

/**
 * UIClass
 */
class UIClass
{
    string name;

    int type;
    Boxtype box;
    string superclass;
    long[] colors;
    long x, y, w, h;
    string label;
    bool modal = false, non_modal = false;
    bool borderless = false;

    UIItem[] items;

    this(JSONValue item)
    {
        assert(item["widget_type"].str == "widget_class", "Wrong element widget_type!");

        uint32_t tempnamescount = 0;

        this.name = item["name"].str;
        this.superclass = item["subclass"].str.asClassName;

        this.type=cast(int)item["type"].integer;
        this.x = item["xywh"].array[0].integer;
        this.y = item["xywh"].array[1].integer;
        this.w = item["xywh"].array[2].integer;
        this.h = item["xywh"].array[3].integer;
        this.label = item["label"].str;
        this.modal = cast(bool)("modal" in item) && (item["modal"].boolean);
        this.non_modal = cast(bool)("non_modal" in item) && (item["non_modal"].boolean);
        this.borderless = cast(bool)("borderless" in item) && (item["borderless"].boolean);
        this.box = cast(Boxtype) box_from_name(item["box"].str);
        item["colors"].array.each!(x => this.colors ~= x.integer);

        foreach (child; item["children"].array)
        {
            //Skip C Decls
            //if (child["widget_type"].str == "decl")
            //    continue;

            UIItem newitem = new UIItem(child);
            UIItem parent = Get(newitem.parent);
            if (parent)
            {
                parent.items ~= newitem;
            }
            else
            {
                items ~= newitem;
            }
        }
    }

    UIItem Get(string name)
    {
        foreach (item; items)
        {
            if (item.name == name)
            {
                return item;
            }
        }

        return null;
    }

    string constructor()
    {
        return format("super(x,y,w,h,label);");
    }

    string generate()
    {
        string ret = format("class %s: %s{", this.name, this.superclass);

        foreach (item; items)
        {
            ret ~= item.decl ~ "\n";
        }

        ret ~=`
        private void* swigCPtr;
        this(void* cPtr, bool owned=false){
        	super(cPtr, owned);
        	swigCPtr = cPtr;
        }
        `;

        ret ~= format("this(int x=%d,int y=%d,int w=%d,int h=%d,string label=\"%s\"){\n",
                this.x, this.y, this.w, this.h, this.label);

        ret ~= this.constructor;

        //Colors
        ret~=format("this.color=%d;\nthis.color2=%d;\nthis.selection_color=%d;\n",this.colors[0],this.colors[1],this.colors[2]);

        if (this.borderless)
            ret ~= "this.clear_border()\n;";
        if (this.modal)
            ret ~= "this.set_modal()\n";
        if (this.non_modal)
            ret ~= "this.set_non_modal()\n";

        ret ~= format("this.box=cast(Boxtype)%d; //%s\n", cast(int) this.box, box_names[this.box]);

        foreach (item; items)
        {
            ret ~= item.generate ~ "\n";
        }
        ret ~= "}";

        ret ~= "}";

        return ret;
    }

    override string toString()
    {
        string ret = format("class %s: %s (%d children)\n", this.name,
                this.superclass, this.items.length);
        foreach (child; items)
        {
            ret ~= (child.toString() ~ "\n");
        }

        return ret;
    }
}

string asClassName(string str)
{
    if (str == "")
        return "Group";

    if (str[0 .. 3] == "Fl_")
    {
        return str[3 .. $];
    }

    return str;
}

string generateCompileTime(string fname)(){
    return generate(import(fname));
}

string generate(string jsondata)
{
    JSONValue root = parseJSON(jsondata);

    string data = q{
        import core.stdc.stdint;
        import fltk_d;
    };

    foreach (JSONValue element; root.array)
    {
        switch (element["widget_type"].str)
        {
        case "decl":
            data ~= format("//C DECL: '%s'\n", element["name"].str);
            break;

        case "widget_class":
            UIClass c = new UIClass(element);
            data ~= c.generate;
            data ~= "\n";

            break;
        default:
            assert(0, format("Unknown node widget_type: %s", element["widget_type"].str));
        }
    }

    return data;
}

long box_from_name(string name)
{
    for (int i = 0; i < box_names.length; i++)
    {
        if (box_names[i] == name)
        {
            return i;
        }
    }
    return 0;
}

const string[] box_names = [
    "NO_BOX", "FLAT_BOX", "UP_BOX", "DOWN_BOX", "UP_FRAME", "DOWN_FRAME",
    "THIN_UP_BOX", "THIN_DOWN_BOX", "THIN_UP_FRAME", "THIN_DOWN_FRAME",
    "ENGRAVED_BOX", "EMBOSSED_BOX", "ENGRAVED_FRAME", "EMBOSSED_FRAME",
    "BORDER_BOX", "SHADOW_BOX", "BORDER_FRAME", "SHADOW_FRAME", "ROUNDED_BOX",
    "RSHADOW_BOX", "ROUNDED_FRAME", "RFLAT_BOX", "ROUND_UP_BOX", "ROUND_DOWN_BOX",
    "DIAMOND_UP_BOX", "DIAMOND_DOWN_BOX", "OVAL_BOX", "OSHADOW_BOX", "OVAL_FRAME",
    "OFLAT_BOX", "PLASTIC_UP_BOX", "PLASTIC_DOWN_BOX", "PLASTIC_UP_FRAME",
    "PLASTIC_DOWN_FRAME", "PLASTIC_THIN_UP_BOX", "PLASTIC_THIN_DOWN_BOX",
    "PLASTIC_ROUND_UP_BOX", "PLASTIC_ROUND_DOWN_BOX",
    "GTK_UP_BOX", "GTK_DOWN_BOX", "GTK_UP_FRAME", "GTK_DOWN_FRAME",
    "GTK_THIN_UP_BOX", "GTK_THIN_DOWN_BOX", "GTK_THIN_UP_FRAME",
    "GTK_THIN_DOWN_FRAME", "GTK_ROUND_UP_BOX", "GTK_ROUND_DOWN_BOX",
    "GLEAM_UP_BOX", "GLEAM_DOWN_BOX", "GLEAM_UP_FRAME", "GLEAM_DOWN_FRAME",
    "GLEAM_THIN_UP_BOX", "GLEAM_THIN_DOWN_BOX", "GLEAM_ROUND_UP_BOX",
    "GLEAM_ROUND_DOWN_BOX", "FREE_BOXTYPE"
];
