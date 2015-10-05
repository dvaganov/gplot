using Cairo;

namespace Plot
{
    const int mm = 10;
    const int cm = 100;
}

public class Plot.PlotView : Gtk.DrawingArea
{
    public double width {get; set; default = 6*cm;}
    public double height {get; set; default = 6*cm;}
    public double padding {get; set; default = mm;}
    
    public Background bkg;
    public Axes axes_x;
    public Axes axes_y;
    public Curve curve1;
    
    public PlotView () {
        margin = mm;
        width_request = (int) (width + 2*margin);
        height_request = (int) (height + 2*margin);
        add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
        button_press_event.connect ((event) => 
        {
            if (event.button == 1 & event.type == Gdk.EventType.BUTTON_PRESS)
            {
                curve1.transform_cb (this, event);
            }
            queue_draw ();
            return true;
        });
        button_release_event.connect ((event) => 
        {
            curve1.remove_motion_cb (this);
            return true;
        });
        
        bkg = new Background ();
        bkg.width = width;
        bkg.height = height;
        
        axes_x = new Axes (Axes.Type.X);
        axes_x.min = padding;
        axes_x.max = width - padding;
        axes_x.intersection = 0.5*height;
        axes_x.major_tick = 5;
        
        axes_y = new Axes (Axes.Type.Y);
        axes_y.min = padding;
        axes_y.max = height - padding;
        axes_y.intersection = 0.5*width;
        
        curve1 = new Curve ();
        curve1.coords = {{5*cm, 5*cm}, {5*cm, 2*cm}, {3*cm, 5*cm}, {7*cm, 4*cm}};
        
        var scatters = new Scatters ();
        scatters.points = {1*cm, 1*cm};
        
        draw.connect ((context) => {
        //FIXME: Not drawn if nothing changes
            // Create border
            context.translate (margin, margin);
            
            // Draw a paper:
            bkg.draw (context);
            bkg.draw_grid (context);
            
            // Draw axes
            axes_x.draw (context);
            axes_y.draw (context);
            
            curve1.draw (context);
            
            scatters.draw (context);
            
            return true;
        });
        
        queue_draw ();
    }
}
