extends Node2D

var path_png="res://binary/images/charas/"
var path_res="res://anim_sprite/"

func customComparison(a, b):
    return a[0] < b[0]

func process_anim(anim_sprite, anim_name, chara_name):
    var anim_name_ori=anim_name
    if anim_name=="idle":
        anim_name="hit"
    anim_sprite.add_animation(anim_name)
    anim_sprite.set_animation_speed(anim_name, 10)
    if "mov" in anim_name:
        anim_sprite.set_animation_loop(anim_name, true)
    else:
        anim_sprite.set_animation_loop(anim_name, false)
    var chara_root=path_png+chara_name+"/"+anim_name_ori+"/"
    var dir = Directory.new()
    if dir.open(chara_root) == OK:
        dir.list_dir_begin()
        var file_name = "."
        var frame_names=[]
        while file_name != "":
            file_name = dir.get_next()
            if "import" in file_name:
                continue
            if not "png" in file_name:
                continue
            var str_split = file_name.split(".")[0].split("_")
            var frame_count=int(str_split[-1])
            frame_names.append([frame_count,file_name])
        frame_names.sort_custom(self, "customComparison")
        for name in frame_names:
            file_name=name[1]
            var texture = load(chara_root+file_name)
            # print(file_name)
            anim_sprite.add_frame(anim_name,texture,name[0])

func process_chara(chara_name):
    var dir = Directory.new()
    var chara_root=path_png+chara_name
    var anim_sprite= SpriteFrames.new()
    anim_sprite.remove_animation("default")
    if dir.open(chara_root) == OK:
        dir.list_dir_begin()
        var file_name = "."
        while file_name != "":
            file_name = dir.get_next()
            if dir.current_is_dir() and file_name!="." and file_name!="..":
                process_anim(anim_sprite, file_name,chara_name)
    ResourceSaver.save(path_res+chara_name+".tres", anim_sprite)

func _ready():
    var dir = Directory.new()
    if dir.open(path_png) == OK:
        dir.list_dir_begin()
        var file_name = "."
        while file_name != "":
            file_name = dir.get_next()
            if dir.current_is_dir() and file_name!="." and file_name!="..":
                process_chara(file_name)
