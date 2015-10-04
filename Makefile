SRC = src/main.vala src/window.vala src/plot_view.vala src/shapes.vala
PKG = --pkg gtk+-3.0

all: gplot

gplot: $(SRC)
  valac $(PKG) -o gplot $(SRC)
