SRC = src/main.vala src/window.vala src/view.vala src/shapes.vala src/layer.vala src/axes.vala src/plot_namespace.vala src/curve.vala src/scatters.vala
PKG = --pkg gtk+-3.0

all: gplot

gplot: $(SRC)
	valac $(PKG) -o gplot $(SRC)
