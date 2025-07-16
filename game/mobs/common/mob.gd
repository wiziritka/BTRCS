class_name Mob
extends Entity

## Моб.
##
## Базовый класс для различных мобов - сущностей, не являющихся игроками, способных двигаться
## и искать пути.

## [NavigationAgent2D], которым пользуется этот моб.
@onready var agent: NavigationAgent2D = $NavigationAgent2D
