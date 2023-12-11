
#=
== Получение макета лыжника по кадрам видео цикла.
=#


#=============================================================================#
# Метка макета:
mutable struct Point
	x::Number
	y::Number
end

# Один этап движения макета:
mutable struct Stage
	points::Array{Point, 1}
end

# Создание этапа макета по умолчанию:
function Stage()
	default_points = [
		Point(25, 275),
		Point(175, 275),
		Point(100, 275),
		Point(75, 250),
		Point(100, 200),
		Point(75, 175),
		Point(100, 75),
		Point(125, 125),
		Point(150, 75),
		Point(125, 225)
		]
	
	Stage(default_points)
end

# Весь макет:
mutable struct Model
	name::String
	r::Array{Stage, 1}
end

# Создание макета:
function Model(name::String)
	Model(name, Stage[])
end

# Добавить 
function add_stage!(model::Model)
	push!(model.r, Stage())
end

#=============================================================================#

# Норма вектора:
function norm(A::Point)
	return √(A.x^2 + A.y^2)
end

# Получение угла по трем точкам:
function get_angle(A::Point, B::Point, C::Point)
	a = Point(A.x - B.x, A.y - B.y)
	b = Point(C.x - B.x, C.y - B.y)

	return acosd((a.x*b.x + a.y*b.y)/(norm(a)*norm(b)))
end


# Запись модели в файл:
function save_point_to_file(model::Model, file_name::String)
	touch(file_name)
	file = open(file_name,  "w")

	for i in model.r
		r = i.points
        for j in 1:10
            write(file, string(r[j].x) * "\n")
            write(file, string(r[j].y) * "\n")
        end
	end

	close(file)
end

# Загрузка меток из файла:
function load_point_from_file(model::Model, file_name::String)
    file = open(file_name, "r")
    str = readlines(file)
    
    temp_str = 1
    for i in model.r
        r = i.points
        for j = 1:10
            r[j].x = parse(Float64, str[temp_str])
            r[j].y = parse(Float64, str[temp_str+1])
            temp_str += 2
        end
    end
    
    close(file)
end


function save_angle_to_file(model::Model, file_name::String, a::Int, b::Int, c::Int)
    touch(file_name)
	file = open(file_name,  "w")
	for i in model.r
		r = i.points
		write(file, string(get_angle(r[a], r[b], r[c])), "\n") 
    end
	close(file)
end



function save_exterior_angle_to_file(model::Model, file_name::String, a::Int, b::Int, c::Int)
    touch(file_name)
    file = open(file_name,  "w")
    for i in model.r
        r = i.points
        write(file, string(180 - get_angle(r[a], r[b], r[c])), "\n") 
    end
    close(file)
end



# Сохранить углы в файл:
function save_angles(model::Model, path::String)

    save_exterior_angle_to_file(model, path*"shoulder.txt", 6, 7, 8) # Плечо.
    save_angle_to_file(model, path*"elbow.txt", 9, 8, 7) # Локоть.
    save_angle_to_file(model, path*"wrist.txt", 8, 9, 10) # Запястье.

end

#=============================================================================#


# Максимальная ширина и высота для моего монитора:
WIDTH = 1920
HEIGHT = 1080

# Цвет фона вокруг изображения:
BACKGROUND = colorant"#1f1f1f"

# Параметр для включения игры:
game_ongoing = true 

# Параметры макета:
radius = 1 # Радиус метки.
color_point = colorant"#f10f0f" # Цвет для метки на тела.
color_line = colorant"#00f805" # Цвет линии, связывающей метки.

# Предварительное описание файла:
file_name = "frame" # Имя файла.
file_format = ".png"
number_frames = 83 # Номер последнего кадра.

# Глобальные переменные для работы программы с моделью:
model = Model(file_name) # Модель, в которую записываются данные.
current_stage = 1 # Текущий этап движения модели.
current_point = 1 # Текущая метка для редактирования.

for i = 1:number_frames
    add_stage!(model)
end

# Глобальные переменные для работы с изображением:
images = Actor[] # Список кадров видео.

# Загружаем кадры видео лыжника:
for i = 1:number_frames
    push!(images, Actor(file_name*"$i"*file_format))
end



# Функция отображения меток и изображения с лыжником:
function draw()
    global current_stage
	global current_point

    # Нарисуем текущее изображение лыжника:
    images[current_stage].center = (WIDTH/2, HEIGHT/2)
    draw(images[current_stage])

	r = model.r[current_stage].points

    # Рисование линий для соединения меток:
    for i in 2:10
        draw(Line(r[i-1].x, r[i-1].y, r[i].x, r[i].y), color_line)
    end

    # Рисование всех меток лыжника:
    for i in 1:10
        draw(Circle(r[i].x, r[i].y, radius), color_point, fill=true)
    end

    # Рисование выделения для текущей метки:
    draw(Circle(r[current_point].x, r[current_point].y, radius*6), color_point)
end

# Выбор кадра для создания макета и выбрать текущую метку:
function on_key_down(g, k)
    global current_stage
    global current_point

    # Переделать этот кадр:
    if k == Keys.R 
        model.r[current_stage] = Stage()
    end

    # Сохранить метки в файл:
    if k == Keys.S 
        save_point_to_file(model, "results//point.txt")
    end

    # Загрузить метки из файла:
    if k == Keys.L
        load_point_from_file(model, "results//point.txt")
    end

    # Сохранить углы в файл:
    if k == Keys.A 
        #save_angles(model, "results//")
    end

    # Следующий кадр:
    if k == Keys.RIGHT
        if current_stage != number_frames
            current_stage += 1
			current_point = 1
        end
    end

    # Предыдущий кадр:
    if k == Keys.LEFT
        if current_stage != 1
            current_stage -= 1
			current_point = 1
        end
    end

    # Следующая метка:
    if k == Keys.UP
        current_point == 10 ? current_point = 1 : current_point += 1
    end

    # Предыдущая метка:
    if k == Keys.DOWN
        current_point == 1 ? current_point = 10 : current_point -= 1
    end
end

# Прикрепляем метки по очереди:
function on_mouse_down(g, pos)
    global current_point

	r = model.r[current_stage].points

    if game_ongoing
        r[current_point].x = pos[1]
        r[current_point].y = pos[2]

        current_point == 10 ? current_point = 1 : current_point += 1
    end
end










