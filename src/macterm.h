/* Display module for Mac OS.
   Copyright (C) 2000-2008 Free Software Foundation, Inc.
   Copyright (C) 2009-2014  YAMAMOTO Mitsuharu

This file is part of GNU Emacs Mac port.

GNU Emacs Mac port is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GNU Emacs Mac port is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs Mac port.  If not, see <http://www.gnu.org/licenses/>.  */

/* Originally contributed by Andrew Choi (akochoi@mac.com) for Emacs 21.  */

#include "macgui.h"
#include "frame.h"

#define RGB_TO_ULONG(r, g, b) (((r) << 16) | ((g) << 8) | (b))
#define ARGB_TO_ULONG(a, r, g, b) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b))

#define ALPHA_FROM_ULONG(color) ((color) >> 24)
#define RED_FROM_ULONG(color) (((color) >> 16) & 0xff)
#define GREEN_FROM_ULONG(color) (((color) >> 8) & 0xff)
#define BLUE_FROM_ULONG(color) ((color) & 0xff)

/* Do not change `* 0x101' in the following lines to `<< 8'.  If
   changed, image masks in 1-bit depth will not work. */
#define RED16_FROM_ULONG(color) (RED_FROM_ULONG(color) * 0x101)
#define GREEN16_FROM_ULONG(color) (GREEN_FROM_ULONG(color) * 0x101)
#define BLUE16_FROM_ULONG(color) (BLUE_FROM_ULONG(color) * 0x101)

#define BLACK_PIX_DEFAULT(f) RGB_TO_ULONG(0,0,0)
#define WHITE_PIX_DEFAULT(f) RGB_TO_ULONG(255,255,255)

/* Structure recording bitmaps and reference count.
   If REFCOUNT is 0 then this record is free to be reused.  */

struct mac_bitmap_record
{
  char *bitmap_data;
  char *file;
  int refcount;
  int height, width;
};


/* For each display (currently only one on mac), we have a structure that
   records information about it.  */

struct mac_display_info
{
  /* Chain of all mac_display_info structures.  */
  struct mac_display_info *next;

  /* The generic display parameters corresponding to this display. */
  struct terminal *terminal;

  /* This is a cons cell of the form (NAME . FONT-LIST-CACHE).  */
  Lisp_Object name_list_element;

  /* Number of frames that are on this display.  */
  int reference_count;

  /* Dots per inch of the screen.  */
  double resx, resy;

  /* Number of planes on this screen.  */
  int n_planes;

  /* Whether the screen supports color */
  int color_p;

  /* Dimensions of this screen.  */
  int height, width;

  /* Mask of things that cause the mouse to be grabbed.  */
  int grabbed;

#if 0
  /* Emacs bitmap-id of the default icon bitmap for this frame.
     Or -1 if none has been allocated yet.  */
  ptrdiff_t icon_bitmap_id;

#endif
  /* The root window of this screen.  */
  Window root_window;

  /* The cursor to use for vertical scroll bars.  */
  Cursor vertical_scroll_bar_cursor;

  /* Resource data base */
  XrmDatabase xrdb;

  /* Minimum width over all characters in all fonts in font_table.  */
  int smallest_char_width;

  /* Minimum font height over all fonts in font_table.  */
  int smallest_font_height;

  /* Reusable Graphics Context for drawing a cursor in a non-default face. */
  GC scratch_cursor_gc;

  /* Information about the range of text currently shown in
     mouse-face.  */
  Mouse_HLInfo mouse_highlight;

  /* Default name for all frames on this display.  */
  char *mac_id_name;

  /* The number of fonts opened for this display.  */
  int n_fonts;

  /* Pointer to bitmap records.  */
  struct mac_bitmap_record *bitmaps;

  /* Allocated size of bitmaps field.  */
  ptrdiff_t bitmaps_size;

  /* Last used bitmap index.  */
  ptrdiff_t bitmaps_last;

  /* The frame (if any) which has the window that has keyboard focus.
     Zero if none.  This is examined by Ffocus_frame in macfns.c.  Note
     that a mere EnterNotify event can set this; if you need to know the
     last frame specified in a FocusIn or FocusOut event, use
     x_focus_event_frame.  */
  struct frame *x_focus_frame;

  /* The last frame mentioned in a FocusIn or FocusOut event.  This is
     separate from x_focus_frame, because whether or not LeaveNotify
     events cause us to lose focus depends on whether or not we have
     received a FocusIn event for it.  */
  struct frame *x_focus_event_frame;

  /* The frame which currently has the visual highlight, and should get
     keyboard input (other sorts of input have the frame encoded in the
     event).  It points to the focus frame's selected window's
     frame.  It differs from x_focus_frame when we're using a global
     minibuffer.  */
  struct frame *x_highlight_frame;

  /* The frame waiting to be auto-raised in XTread_socket.  */
  struct frame *x_pending_autoraise_frame;

  /* The frame where the mouse was last time we reported a ButtonPress event.  */
  struct frame *last_mouse_frame;

  /* The frame where the mouse was last time we reported a mouse position.  */
  struct frame *last_mouse_glyph_frame;

  /* Where the mouse was last time we reported a mouse position.
     This is a rectangle on last_mouse_glyph_frame.  */
  NativeRectangle last_mouse_glyph;

  /* Time of last mouse movement on this display.  This is a hack because
     we would really prefer that XTmouse_position would return the time
     associated with the position it returns, but there doesn't seem to be
     any way to wrest the time-stamp from the server along with the position
     query.  So, we just keep track of the time of the last movement we
     received, and return that in hopes that it's somewhat accurate.  */
  Time last_mouse_movement_time;

  /* This is a button event that wants to activate the menubar.
     We save it here until the command loop gets to think about it.  */
  EventRef saved_menu_event;
};

/* This checks to make sure we have a display.  */
extern void check_mac (void);

#define x_display_info mac_display_info

/* This is a chain of structures for all the X displays currently in use.  */
extern struct x_display_info *x_display_list;

/* This is a chain of structures for all the displays currently in use.  */
extern struct mac_display_info one_mac_display_info;

extern struct mac_display_info *mac_term_init (Lisp_Object, char *, char *);

/* The collection of data describing a window on the Mac.  */
struct mac_output
{
  /* Menubar "widget" handle.  */
  int menubar_widget;

  /* Here are the Graphics Contexts for the default font.  */
  GC normal_gc;				/* Normal video */
  GC cursor_gc;				/* cursor drawing */

  /* The window used for this frame.
     May be zero while the frame object is being created
     and the window has not yet been created.  */
  Window window_desc;

  /* The window that is the parent of this window.
     Usually this is a window that was made by the window manager,
     but it can be the root window, and it can be explicitly specified
     (see the explicit_parent field, below).  */
  Window parent_desc;

  /* Default ASCII font of this frame. */
  struct font *font;

  /* The baseline offset of the default ASCII font.  */
  int baseline_offset;

  /* If a fontset is specified for this frame instead of font, this
     value contains an ID of the fontset, else -1.  */
  int fontset;

  /* Pixel values used for various purposes.
     border_pixel may be -1 meaning use a gray tile.  */
  unsigned long cursor_pixel;
  unsigned long border_pixel;
  unsigned long mouse_pixel;
  unsigned long cursor_foreground_pixel;

  /* Descriptor for the cursor in use for this window.  */
  Cursor text_cursor;
  Cursor nontext_cursor;
  Cursor modeline_cursor;
  Cursor hand_cursor;
  Cursor hourglass_cursor;
  Cursor horizontal_drag_cursor;
  Cursor vertical_drag_cursor;
  Cursor current_cursor;

  /* True means our parent is another application's window
     and was explicitly specified.  */
  bool_bf explicit_parent : 1;

  /* True means tried already to make this frame visible.  */
  bool_bf asked_for_visible : 1;

  /* True means this frame is for tooltip.  */
  bool_bf tooltip_p : 1;

  /* True means x_check_fullscreen is not called yet after fullscreen
     request for this frame.  */
  bool_bf check_fullscreen_needed_p : 1;

  /* True means this frame uses a native tool bar (as opposed to a
     toolkit one).  */
  bool_bf native_tool_bar_p : 1;

  /* Backing scale factor (1 or 2), used for rendering images.  */
  unsigned backing_scale_factor : 2;

  /* Relief GCs, colors etc.  */
  struct relief
  {
    GC gc;
    unsigned long pixel;
  }
  black_relief, white_relief;

  /* The background for which the above relief GCs were set up.
     They are changed only when a different background is involved.  */
  unsigned long relief_background;

  /* Width of the internal border.  */
  int internal_border_width;

  /* Hints for the size and the position of a window.  */
  XSizeHints *size_hints;

  /* This variable records the gravity value of the window position if
     the window has an external tool bar when it is created.  The
     position of the window is adjusted using this information when
     the tool bar is first redisplayed.  Once the tool bar is
     redisplayed, it is set to 0 in order to avoid further
     adjustment.  */
  int toolbar_win_gravity;

  /* Quartz 2D graphics context.  */
  CGContextRef cg_context;
};

/* Return the X output data for frame F.  */
#define FRAME_X_OUTPUT(f) ((f)->output_data.mac)

/* Return the Mac window used for displaying data in frame F.  */
#define FRAME_MAC_WINDOW(f) ((f)->output_data.mac->window_desc)
#define FRAME_X_WINDOW(f) ((f)->output_data.mac->window_desc)

#define FRAME_FONT(f) ((f)->output_data.mac->font)
#define FRAME_FONTSET(f) ((f)->output_data.mac->fontset)

#define FRAME_BASELINE_OFFSET(f) ((f)->output_data.mac->baseline_offset)

#define FRAME_SIZE_HINTS(f) ((f)->output_data.mac->size_hints)
#define FRAME_TOOLTIP_P(f) ((f)->output_data.mac->tooltip_p)
#define FRAME_CHECK_FULLSCREEN_NEEDED_P(f) \
  ((f)->output_data.mac->check_fullscreen_needed_p)
#define FRAME_NATIVE_TOOL_BAR_P(f) ((f)->output_data.mac->native_tool_bar_p)
#define FRAME_BACKING_SCALE_FACTOR(f) \
  ((f)->output_data.mac->backing_scale_factor)

/* This gives the mac_display_info structure for the display F is on.  */
#define FRAME_DISPLAY_INFO(f) (&one_mac_display_info)

/* This is the `Display *' which frame F is on.  */
#define FRAME_MAC_DISPLAY(f) (0)
#define FRAME_X_DISPLAY(f) (0)

/* Mac-specific scroll bar stuff.  */

/* We represent scroll bars as lisp vectors.  This allows us to place
   references to them in windows without worrying about whether we'll
   end up with windows referring to dead scroll bars; the garbage
   collector will free it when its time comes.

   We use struct scroll_bar as a template for accessing fields of the
   vector.  */

struct scroll_bar {

  /* These fields are shared by all vectors.  */
  struct vectorlike_header header;

  /* The window we're a scroll bar for.  */
  Lisp_Object window;

  /* The next and previous in the chain of scroll bars in this frame.  */
  Lisp_Object next, prev;

  /* Fields from `mac_control_ref' down will not be traced by the GC.  */

  /* The Mac control reference of this scroll bar.  */
  void *mac_control_ref;

  /* The position and size of the scroll bar in pixels, relative to the
     frame.  */
  int top, left, width, height;

  /* True if redraw needed in the next XTset_vertical_scroll_bar call.  */
  bool_bf redraw_needed_p : 1;
};

/* Turning a lisp vector value into a pointer to a struct scroll_bar.  */
#define XSCROLL_BAR(vec) ((struct scroll_bar *) XVECTOR (vec))


/* Extract the reference to the scroller control from a struct
   scroll_bar.  */
#define SCROLL_BAR_SCROLLER(ptr) ((__bridge EmacsScroller *) (ptr)->mac_control_ref)

/* Store the reference to a scroller control in a struct
   scroll_bar.  */
#define SET_SCROLL_BAR_SCROLLER(ptr, ref) ((ptr)->mac_control_ref = (__bridge void *) (ref))

/* Size of hourglass controls */
#define HOURGLASS_WIDTH (18)
#define HOURGLASS_HEIGHT (18)
#define HOURGLASS_TOP_MARGIN (2)
#define HOURGLASS_RIGHT_MARGIN (32)

/* Some constants that are used locally.  */
/* Creator code for Emacs on Mac OS.  */
enum {
  MAC_EMACS_CREATOR_CODE	= 'EMAx'
};

/* Apple event descriptor types */
enum {
  TYPE_FILE_NAME		= 'fNam'
};

/* Keywords for Apple event attributes */
enum {
  KEY_EMACS_SUSPENSION_ID_ATTR	= 'esId' /* typeUInt32 */
};

/* Some constants that are not defined in older versions.  */
/* kCGBitmapByteOrder32Host is defined in Universal SDK for 10.4 but
   not in PPC SDK for 10.4.0.  */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050 && !defined (kCGBitmapByteOrder32Host)
#define kCGBitmapByteOrder32Host 0
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED == 1060
BLOCK_EXPORT void _Block_object_assign (void *, const void *, const int) AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER;
BLOCK_EXPORT void _Block_object_dispose (const void *, const int) AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER;
BLOCK_EXPORT void * _NSConcreteGlobalBlock[32] AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER;
BLOCK_EXPORT void * _NSConcreteStackBlock[32] AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER;
#endif

/* From macfns.c.  */

extern void x_free_gcs (struct frame *);

/* Defined in macterm.c.  */

extern void x_set_window_size (struct frame *, int, int, int, bool);
extern void x_set_mouse_position (struct frame *, int, int);
extern void x_set_mouse_pixel_position (struct frame *, int, int);
extern void x_raise_frame (struct frame *);
extern void x_lower_frame (struct frame *);
extern void x_delete_terminal (struct terminal *terminal);
extern Pixmap mac_create_pixmap (unsigned int, unsigned int, unsigned int);
extern Pixmap mac_create_pixmap_from_bitmap_data (char *,
						  unsigned int,
						  unsigned int,
						  unsigned long,
						  unsigned long,
						  unsigned int);
extern void mac_free_pixmap (Pixmap);
extern GC mac_create_gc (unsigned long, XGCValues *);
#if DRAWING_USE_GCD
extern GC mac_duplicate_gc (GC);
#endif
extern void mac_free_gc (GC);
extern void mac_set_foreground (GC, unsigned long);
extern void mac_set_background (GC, unsigned long);
extern void mac_draw_line_to_pixmap (Pixmap, GC, int, int, int, int);
extern void mac_clear_area (struct frame *, int, int, int, int);
extern int mac_quit_char_key_p (UInt32, UInt32);
#define x_display_pixel_height(dpyinfo)	((dpyinfo)->height)
#define x_display_pixel_width(dpyinfo)	((dpyinfo)->width)
#define XCreatePixmap(display, w, width, height, depth) \
  mac_create_pixmap (width, height, depth)
#define XCreatePixmapFromBitmapData(display, w, data, width, height, fg, bg, depth) \
  mac_create_pixmap_from_bitmap_data (data, width, height, fg, bg, depth)
#define XFreePixmap(display, pixmap)	mac_free_pixmap (pixmap)
#define XChangeGC(display, gc, mask, xgcv)	mac_change_gc (gc, mask, xgcv)
#define XCreateGC(display, d, mask, xgcv)	mac_create_gc (mask, xgcv)
#define XFreeGC(display, gc)	mac_free_gc (gc)
#define XGetGCValues(display, gc, mask, xgcv)	\
  mac_get_gc_values (gc, mask, xgcv)
#define XSetForeground(display, gc, color)	mac_set_foreground (gc, color)
#define XSetBackground(display, gc, color)	mac_set_background (gc, color)
#define XDrawLine(display, p, gc, x1, y1, x2, y2)	\
  mac_draw_line_to_pixmap (p, gc, x1, y1, x2, y2)

extern CGColorSpaceRef mac_cg_color_space_rgb;
extern int mac_scale_mismatch_detection;
enum
  {
    SCALE_MISMATCH_DONT_DETECT,
    SCALE_MISMATCH_DETECT_NOT_1X,
    SCALE_MISMATCH_DETECT_NOT_2X,
    SCALE_MISMATCH_DETECTED,
  };

extern void x_set_sticky (struct frame *, Lisp_Object, Lisp_Object);

/* Defined in macselect.c */

extern void x_clear_frame_selections (struct frame *);

/* Defined in macfns.c */

extern bool mac_defined_color (struct frame *, const char *, XColor *, bool);
extern void mac_update_title_bar (struct frame *, int);
extern Lisp_Object x_get_focus_frame (struct frame *);

/* Defined in mac.c.  */

extern Lisp_Object mac_four_char_code_to_string (FourCharCode);
extern Boolean mac_string_to_four_char_code (Lisp_Object, FourCharCode *);
extern Lisp_Object mac_aedesc_to_lisp (const AEDesc *);
extern OSErr mac_ae_put_lisp (AEDescList *, UInt32, Lisp_Object);
extern OSErr create_apple_event_from_lisp (Lisp_Object, AppleEvent *);
extern OSErr create_apple_event (AEEventClass, AEEventID, AppleEvent *);
extern Lisp_Object mac_event_parameters_to_lisp (EventRef, UInt32,
						 const EventParamName *,
						 const EventParamType *);
extern CFStringRef cfstring_create_with_utf8_cstring (const char *);
extern CFStringRef cfstring_create_with_string_noencode (Lisp_Object);
extern CFStringRef cfstring_create_with_string (Lisp_Object);
extern Lisp_Object cfdata_to_lisp (CFDataRef);
extern Lisp_Object cfstring_to_lisp_nodecode (CFStringRef);
extern Lisp_Object cfstring_to_lisp (CFStringRef);
extern Lisp_Object cfstring_to_lisp_utf_16 (CFStringRef);
extern Lisp_Object cfnumber_to_lisp (CFNumberRef);
extern Lisp_Object cfdate_to_lisp (CFDateRef);
extern Lisp_Object cfboolean_to_lisp (CFBooleanRef);
extern Lisp_Object cfobject_desc_to_lisp (CFTypeRef);
extern Lisp_Object cfobject_to_lisp (CFTypeRef, int, int);
extern Lisp_Object cfproperty_list_to_lisp (CFPropertyListRef, int, int);
extern CFPropertyListRef cfproperty_list_create_with_lisp (Lisp_Object);
extern Lisp_Object cfproperty_list_to_string (CFPropertyListRef,
					      CFPropertyListFormat);
extern CFPropertyListRef cfproperty_list_create_with_string (Lisp_Object);
extern int init_wakeup_fds (void);
extern void xrm_merge_string_database (XrmDatabase, const char *);
extern Lisp_Object xrm_get_resource (XrmDatabase, const char *,
				     const char *);
extern XrmDatabase xrm_get_preference_database (const char *);
extern int mac_service_provider_registered_p (void);
extern int mac_select (int, fd_set *, fd_set *, fd_set *,
		       struct timespec const *, sigset_t const *);

/* Defined in macappkit.m.  */

extern Lisp_Object mac_nsobject_to_lisp (CFTypeRef);
extern void mac_alert_sound_play (void);
extern double mac_appkit_version (void);
extern double mac_system_uptime (void);
extern Boolean mac_is_current_process_frontmost (void);
extern void mac_bring_current_process_to_front (Boolean);
extern OSStatus install_application_handler (void);
extern void mac_set_frame_window_title (struct frame *, CFStringRef);
extern void mac_set_frame_window_modified (struct frame *, Boolean);
extern Boolean mac_is_frame_window_visible (struct frame *);
extern Boolean mac_is_frame_window_collapsed (struct frame *);
extern void mac_bring_frame_window_to_front (struct frame *);
extern void mac_send_frame_window_behind (struct frame *);
extern void mac_hide_frame_window (struct frame *);
extern void mac_show_frame_window (struct frame *);
extern OSStatus mac_collapse_frame_window (struct frame *, Boolean);
extern Boolean mac_is_frame_window_frontmost (struct frame *);
extern void mac_activate_frame_window (struct frame *);
extern OSStatus mac_move_frame_window_structure (struct frame *,
						 short, short);
extern void mac_move_frame_window (struct frame *, short, short, Boolean);
extern void mac_size_frame_window (struct frame *, short, short, Boolean);
extern OSStatus mac_set_frame_window_alpha (struct frame *, CGFloat);
extern OSStatus mac_get_frame_window_alpha (struct frame *, CGFloat *);
extern void mac_get_global_mouse (Point *);
extern Boolean mac_is_frame_window_toolbar_visible (struct frame *);
#if MAC_OS_X_VERSION_MIN_REQUIRED < 1070
extern CGRect mac_rect_make (struct frame *, CGFloat, CGFloat,
			     CGFloat, CGFloat);
#else
#define mac_rect_make(f, x, y, w, h)	CGRectMake (x, y, w, h)
#endif
extern void mac_get_window_structure_bounds (struct frame *,
					     NativeRectangle *);
extern void mac_get_frame_mouse (struct frame *, Point *);
extern void mac_convert_frame_point_to_global (struct frame *, int *,
					       int *);
extern void mac_update_proxy_icon (struct frame *);
extern void mac_set_frame_window_background (struct frame *,
					     unsigned long);
extern void mac_update_begin (struct frame *);
extern void mac_update_end (struct frame *);
extern void mac_cursor_to (int, int, int, int);
extern void x_flush (struct frame *);
extern void mac_flush (struct frame *);
extern void mac_create_frame_window (struct frame *);
extern void mac_dispose_frame_window (struct frame *);
extern void mac_change_frame_window_wm_state (struct frame *, WMState,
					      WMState);
extern CGContextRef mac_begin_cg_clip (struct frame *, GC);
extern void mac_end_cg_clip (struct frame *);
#if DRAWING_USE_GCD
extern void mac_draw_to_frame (struct frame *, GC, void (^) (CGContextRef, GC));
#endif
extern Lisp_Object mac_display_monitor_attributes_list (struct mac_display_info *);
extern void mac_create_scroll_bar (struct scroll_bar *);
extern void mac_dispose_scroll_bar (struct scroll_bar *);
extern void mac_update_scroll_bar_bounds (struct scroll_bar *);
extern void mac_redraw_scroll_bar (struct scroll_bar *);
extern void x_set_toolkit_scroll_bar_thumb (struct scroll_bar *,
					    int, int, int);
extern int mac_get_default_scroll_bar_width (struct frame *);
extern int mac_font_panel_visible_p (void);
extern OSStatus mac_show_hide_font_panel (void);
extern OSStatus mac_set_font_info_for_selection (struct frame *, int, int,
						 int, Lisp_Object);
extern EventTimeout mac_run_loop_run_once (EventTimeout);
extern void update_frame_tool_bar (struct frame *f);
extern void free_frame_tool_bar (struct frame *f);
extern void mac_show_hourglass (struct frame *);
extern void mac_hide_hourglass (struct frame *);
extern Lisp_Object mac_file_dialog (Lisp_Object, Lisp_Object, Lisp_Object,
				    Lisp_Object, Lisp_Object);
extern Lisp_Object mac_font_dialog (struct frame *f);
extern int mac_activate_menubar (struct frame *);
extern OSStatus mac_get_selection_from_symbol (Lisp_Object, int,
					       Selection *);
extern int mac_valid_selection_target_p (Lisp_Object);
extern OSStatus mac_clear_selection (Selection *);
extern Lisp_Object mac_get_selection_ownership_info (Selection);
extern int mac_valid_selection_value_p (Lisp_Object, Lisp_Object);
extern OSStatus mac_put_selection_value (Selection, Lisp_Object,
					     Lisp_Object);
extern int mac_selection_has_target_p (Selection, Lisp_Object);
extern Lisp_Object mac_get_selection_value (Selection, Lisp_Object);
extern Lisp_Object mac_get_selection_target_list (Selection);
extern Lisp_Object mac_dnd_default_known_types (void);

#if defined (__clang__) && MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
#define MAC_USE_AUTORELEASE_LOOP 1
extern void mac_autorelease_loop (Lisp_Object (^) (void));
#else
extern void *mac_alloc_autorelease_pool (void);
extern void mac_release_autorelease_pool (void *);
#endif

extern int mac_tracking_area_works_with_cursor_rects_invalidation_p (void);
extern void mac_invalidate_frame_cursor_rects (struct frame *f);
extern void mac_mask_rounded_bottom_corners (struct frame *, CGRect, Boolean);
extern int mac_webkit_supports_svg_p (void);
extern CFArrayRef mac_document_copy_type_identifiers (void);
extern EmacsDocumentRef mac_document_create_with_url (CFURLRef,
						      CFDictionaryRef);
extern EmacsDocumentRef mac_document_create_with_data (CFDataRef,
						       CFDictionaryRef);
extern size_t mac_document_get_page_count (EmacsDocumentRef);
extern void mac_document_copy_page_info (EmacsDocumentRef, size_t, CGSize *,
					 CGColorRef *, CFDictionaryRef *);
extern void mac_document_draw_page (CGContextRef, CGRect, EmacsDocumentRef,
				    size_t);
extern void mac_update_accessibility_status (struct frame *);
extern CFTypeRef mac_sound_create (Lisp_Object, Lisp_Object);
extern void mac_sound_play (CFTypeRef, Lisp_Object, Lisp_Object);

#if DRAWING_USE_GCD
#define MAC_BEGIN_DRAW_TO_FRAME(f, gc, context)			\
  mac_draw_to_frame (f, gc, ^(CGContextRef context, GC gc) {
#define MAC_END_DRAW_TO_FRAME(f)		\
  })
#else
#define MAC_BEGIN_DRAW_TO_FRAME(f, gc, context)		\
  do {CGContextRef context = mac_begin_cg_clip (f, gc)
#define MAC_END_DRAW_TO_FRAME(f)		\
  mac_end_cg_clip (f);} while (0)
#endif

/* Defined in macfont.m */
extern void macfont_update_antialias_threshold (void);
extern void *macfont_get_nsctfont (struct font *);
extern Lisp_Object macfont_nsctfont_to_spec (void *);

/* Defined in xdisp.c */
extern struct glyph *x_y_to_hpos_vpos (struct window *, int, int,
				       int *, int *, int *, int *, int *);
extern void frame_to_window_pixel_xy (struct window *, int *, int *);
extern void rows_from_pos_range (struct window *, ptrdiff_t , ptrdiff_t,
				 Lisp_Object, struct glyph_row **,
				 struct glyph_row **);

/* Defined in macmenu.c */
extern Lisp_Object mac_popup_dialog (struct frame *, Lisp_Object, Lisp_Object);
