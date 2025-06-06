/*
    Copyright © 2022, Inochi2D Project
    Copyright © 2024, nijigenerate Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module nijiui.core.window.appwin;
import nijiui.core.window;
import nijiui.core.app;
import nijiui.core.font;
import nijiui.core;
import nijiui.panel;
import nijiui.toolwindow;
import nijiui.widgets;
import nijiui.input;
import nijilive.core;

import bindbc.sdl;
import bindbc.opengl;
import bindbc.imgui;
import bindbc.imgui.ogl;
import std.string;
import std.path;

import std.stdio;

private {
    __gshared bool isGLLoaded;
}

class InApplicationWindow : InWindow {
private:
    SDL_Window* window;
    ImGuiContext* ctx;
    ImGuiIO* io;
    SDL_GLContext glctx;
    bool done;

    int width_, height_;

    bool show = true;
    
    string[] draggedFiles;
    const(char)* iniPath;
    int throttlingRate = 1;
    int renderThrottlingCount = 0;

    // throttling buffer
    version (SafeThrottling) {
        GLuint fbo = 0;
        GLuint fboTexture = 0;
    }
    
protected:

    final
    ref string[] getDraggedFiles() {
        return draggedFiles;
    }

    /**
        Early update (before UI draws)
    */
    override
    void onEarlyUpdate() {

    }

    /**
        Updates the window
    */
    override
    void onUpdate() {

    }

    /**
        Run post-window close cleanup
    */
    final void cleanup() {

        // Cleanup
        ImGuiOpenGLBackend.shutdown();
        ImGui_ImplSDL2_Shutdown();
        igDestroyContext(ctx);

        SDL_GL_DeleteContext(glctx);
        SDL_DestroyWindow(window);
    }
    

    final
    void initStyling() {
        auto style = igGetStyle();
        
        style.ChildBorderSize = 1;
        style.PopupBorderSize = 1;
        style.FrameBorderSize = 1;
        style.TabBorderSize = 1;

        style.WindowRounding = 4;
        style.ChildRounding = 0;
        style.FrameRounding = 3;
        style.PopupRounding = 6;
        style.ScrollbarRounding = 18;
        style.GrabRounding = 3;
        style.LogSliderDeadzone = 6;
        style.TabRounding = 6;

        style.IndentSpacing = 10;
        style.ItemSpacing.y = 3;
        style.FramePadding.y = 4;

        style.GrabMinSize = 13;
        style.ScrollbarSize = 14;
        style.ChildBorderSize = 1;
    }

    final
    void initDarkMode() {
        auto style = igGetStyle();
        
        style.Colors[ImGuiCol.Text]                   = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
        style.Colors[ImGuiCol.TextDisabled]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
        style.Colors[ImGuiCol.WindowBg]               = ImVec4(0.17f, 0.17f, 0.17f, 1.00f);
        style.Colors[ImGuiCol.ChildBg]                = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        style.Colors[ImGuiCol.PopupBg]                = ImVec4(0.08f, 0.08f, 0.08f, 0.94f);
        style.Colors[ImGuiCol.Border]                 = ImVec4(0.00f, 0.00f, 0.00f, 0.16f);
        style.Colors[ImGuiCol.BorderShadow]           = ImVec4(0.00f, 0.00f, 0.00f, 0.16f);
        style.Colors[ImGuiCol.FrameBg]                = ImVec4(0.12f, 0.12f, 0.12f, 1.00f);
        style.Colors[ImGuiCol.FrameBgHovered]         = ImVec4(0.15f, 0.15f, 0.15f, 0.40f);
        style.Colors[ImGuiCol.FrameBgActive]          = ImVec4(0.22f, 0.22f, 0.22f, 0.67f);
        style.Colors[ImGuiCol.TitleBg]                = ImVec4(0.04f, 0.04f, 0.04f, 1.00f);
        style.Colors[ImGuiCol.TitleBgActive]          = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
        style.Colors[ImGuiCol.MenuBarBg]              = ImVec4(0.05f, 0.05f, 0.05f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.53f);
        style.Colors[ImGuiCol.ScrollbarGrab]          = ImVec4(0.31f, 0.31f, 0.31f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarGrabHovered]   = ImVec4(0.41f, 0.41f, 0.41f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarGrabActive]    = ImVec4(0.51f, 0.51f, 0.51f, 1.00f);
        style.Colors[ImGuiCol.CheckMark]              = ImVec4(0.76f, 0.76f, 0.76f, 1.00f);
        style.Colors[ImGuiCol.SliderGrab]             = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.SliderGrabActive]       = ImVec4(0.60f, 0.60f, 0.60f, 1.00f);
        style.Colors[ImGuiCol.Button]                 = ImVec4(0.39f, 0.39f, 0.39f, 0.40f);
        style.Colors[ImGuiCol.ButtonHovered]          = ImVec4(0.44f, 0.44f, 0.44f, 1.00f);
        style.Colors[ImGuiCol.ButtonActive]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
        style.Colors[ImGuiCol.Header]                 = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.HeaderHovered]          = ImVec4(0.28f, 0.28f, 0.28f, 0.80f);
        style.Colors[ImGuiCol.HeaderActive]           = ImVec4(0.44f, 0.44f, 0.44f, 1.00f);
        style.Colors[ImGuiCol.Separator]              = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.SeparatorHovered]       = ImVec4(0.29f, 0.29f, 0.29f, 0.78f);
        style.Colors[ImGuiCol.SeparatorActive]        = ImVec4(0.47f, 0.47f, 0.47f, 1.00f);
        style.Colors[ImGuiCol.ResizeGrip]             = ImVec4(0.35f, 0.35f, 0.35f, 0.00f);
        style.Colors[ImGuiCol.ResizeGripHovered]      = ImVec4(0.40f, 0.40f, 0.40f, 0.00f);
        style.Colors[ImGuiCol.ResizeGripActive]       = ImVec4(0.55f, 0.55f, 0.56f, 0.00f);
        style.Colors[ImGuiCol.Tab]                    = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TabHovered]             = ImVec4(0.34f, 0.34f, 0.34f, 0.80f);
        style.Colors[ImGuiCol.TabActive]              = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.TabUnfocused]           = ImVec4(0.14f, 0.14f, 0.14f, 0.97f);
        style.Colors[ImGuiCol.TabUnfocusedActive]     = ImVec4(0.17f, 0.17f, 0.17f, 1.00f);
        style.Colors[ImGuiCol.DockingPreview]         = ImVec4(0.62f, 0.68f, 0.75f, 0.70f);
        style.Colors[ImGuiCol.DockingEmptyBg]         = ImVec4(0.20f, 0.20f, 0.20f, 1.00f);
        style.Colors[ImGuiCol.PlotLines]              = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
        style.Colors[ImGuiCol.PlotLinesHovered]       = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
        style.Colors[ImGuiCol.PlotHistogram]          = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.PlotHistogramHovered]   = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TableHeaderBg]          = ImVec4(0.19f, 0.19f, 0.20f, 1.00f);
        style.Colors[ImGuiCol.TableBorderStrong]      = ImVec4(0.31f, 0.31f, 0.35f, 1.00f);
        style.Colors[ImGuiCol.TableBorderLight]       = ImVec4(0.23f, 0.23f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.TableRowBg]             = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        style.Colors[ImGuiCol.TableRowBgAlt]          = ImVec4(1.00f, 1.00f, 1.00f, 0.06f);
        style.Colors[ImGuiCol.TextSelectedBg]         = ImVec4(0.26f, 0.59f, 0.98f, 0.35f);
        style.Colors[ImGuiCol.DragDropTarget]         = ImVec4(1.00f, 1.00f, 0.00f, 0.90f);
        style.Colors[ImGuiCol.NavHighlight]           = ImVec4(0.32f, 0.32f, 0.32f, 1.00f);
        style.Colors[ImGuiCol.NavWindowingHighlight]  = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
        style.Colors[ImGuiCol.NavWindowingDimBg]      = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
        style.Colors[ImGuiCol.ModalWindowDimBg]       = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);

        style.FrameBorderSize = 1;
        style.TabBorderSize = 1;
    }

public:

    ~this() {
        cleanup();
    }

    this(string title, uint width, uint height, int throttlingRate = 1, bool isFullScreen = false) {
        this.width_ = width;
        this.height_ = height;

        // Set up OpenGL context
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

        // Set up buffers + alpha channel
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);

        // Set the app name
        SDL_SetHint(SDL_HINT_APP_NAME, inGetApplication().humanName.toStringz);
        
        version(linux) {
            // Don't disable compositing on Linux
            SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0");
        }

        // Create window with GL and resizing enabled,
        // important to give the GL hint

        if (isFullScreen) {

            window = SDL_CreateWindow(
                title.toStringz, 
                SDL_WINDOWPOS_UNDEFINED, 
                SDL_WINDOWPOS_UNDEFINED, 
                width, 
                height, 
                SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_FULLSCREEN_DESKTOP
            );

        } else {

            window = SDL_CreateWindow(
                title.toStringz, 
                SDL_WINDOWPOS_UNDEFINED, 
                SDL_WINDOWPOS_UNDEFINED, 
                width, 
                height, 
                SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
            );

        }

        // Create context and load GL functions
        glctx = SDL_GL_CreateContext(window);
        SDL_GL_MakeCurrent(window, glctx);
        setThrottlingRate(throttlingRate);

        // Load OpenGL and throw any important errors.
        if (!isGLLoaded) {
            GLSupport support = loadOpenGL();
            switch(support) {
                case GLSupport.noLibrary:
                    throw new Exception("OpenGL library could not be loaded!");

                case GLSupport.noContext:
                    throw new Exception("No valid OpenGL context was found!");

                default: break;
            }
        }

        // Setup imgui context
        ctx = igCreateContext();
        io = igGetIO();
        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;
        version(UIViewports) {
            io.ConfigFlags |= ImGuiConfigFlags.ViewportsEnable;
        }
        io.ConfigWindowsResizeFromEdges = true;
        iniPath = buildPath(inGetAppConfigPath(), "imgui.ini").toStringz;
        io.IniFilename = iniPath;

        // Init ImGui for SDL2 & OpenGL
        ImGui_ImplSDL2_InitForOpenGL(window, glctx);
        ImGuiOpenGLBackend.init("#version 330");

        this.initStyling();
        this.initDarkMode();

        inInitFonts(); 
        inInitPanels();
        uiImInitDialogs();
    }

    void setThrottlingRate(int throttlingRate = 1) {
        this.throttlingRate = throttlingRate;
        version(SafeThrottling) {
            if (throttlingRate > 1) {
                if (ctx && io) {
                    onResized(cast(int)(io.DisplaySize.x), cast(int)(io.DisplaySize.y));
                }
            }
            SDL_GL_SetSwapInterval(throttlingRate > 0 ? 1: 0); // Enable VSync (throttlingRate > 0) or disable (throttlingRate == 0)
        } else {
            SDL_GL_SetSwapInterval(throttlingRate); // Enable VSync (throttlingRate > 0) or disable (throttlingRate == 0)
        }
    }

    void toggleFullscreen() {
        
        if ((SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN_DESKTOP) == 0) {

            SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN_DESKTOP);

        } else {

            SDL_SetWindowFullscreen(window, 0);

        }

    }

    void toggleBorders() {
        
        if ((SDL_GetWindowFlags(window) & SDL_WINDOW_BORDERLESS) == 0) {

            SDL_SetWindowBordered(window, SDL_FALSE);

        } else {

            SDL_SetWindowBordered(window, SDL_TRUE);

        }

    }

    void toggleMaximized() {
        
        if ((SDL_GetWindowFlags(window) & SDL_WINDOW_MAXIMIZED) == 0) {

            SDL_MaximizeWindow(window);

        } else {

            SDL_RestoreWindow(window);

        }

    }

    /**
        Gets whether a window should be processed
    */
    override
    bool shouldProcess() {
        return window !is null && !done && (SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED) == 0; 
    }

    /**
        Update all
    */
    final
    void update() {
        void doUpdate() {
            inUpdateTime();

            // Update important SDL events
            draggedFiles.length = 0;
            SDL_Event event;
            while(SDL_PollEvent(&event)) {
                switch(event.type) {
                    case SDL_QUIT:
                        close();
                        break;

                    case SDL_DROPFILE:
                        draggedFiles ~= cast(string)event.drop.file.fromStringz;
                        SDL_RaiseWindow(window);
                        break;
                    
                    default: 
                        ImGui_ImplSDL2_ProcessEvent(&event);
                        if (event.type == SDL_WINDOWEVENT) {

                            // CLOSE EVENT
                            if (
                                event.window.event == SDL_WINDOWEVENT_CLOSE && 
                                event.window.windowID == SDL_GetWindowID(window)
                            ) close();

                            // RESIZE EVENT
                            if (
                                event.window.event == SDL_WindowEventID.SDL_WINDOWEVENT_RESIZED && 
                                event.window.windowID == SDL_GetWindowID(window)
                            ) {
                                SDL_GL_GetDrawableSize(window, &this.width_, &this.height_);
                                onResized(this.width_, this.height_);
                            }
                        }
                        break;
                }
            }

            // Start the Dear ImGui frame
            ImGuiOpenGLBackend.new_frame();
            ImGui_ImplSDL2_NewFrame();
            igNewFrame();

            // Update input
            inInputUpdate();

            // Allow dragging files in to the main window
            if (draggedFiles.length > 0) {
                if (igBeginDragDropSource(ImGuiDragDropFlags.SourceExtern)) {
                    igSetDragDropPayload("_FILEDROP", &draggedFiles, draggedFiles.sizeof);
                    igBeginTooltip();
                        foreach(file; draggedFiles) {
                            igText(file.toStringz);
                        }
                    igEndTooltip();
                    igEndDragDropSource();
                }
            }

            igDockSpaceOverViewport(null, ImGuiDockNodeFlags.PassthruCentralNode, null);

            // update
            this.onUpdate();

            if (showUI) {

                // Update panels
                inUpdatePanels();

                inUpdateToolWindows();

                uiImRenderDialogs();

                // Update window list
                foreach(win; inWindowListGet()) {
                    win.onEarlyUpdate();
                    win.onUpdate();
                }
            }


            // Rendering
            igRender();

            // Reset GL State
            glViewport(0, 0, cast(int)io.DisplaySize.x, cast(int)io.DisplaySize.y);
            glClearColor(0, 0, 0, 0);
            glClear(GL_COLOR_BUFFER_BIT);

            // Run early update
            this.onEarlyUpdate();

            // Run UI Render
            ImGuiOpenGLBackend.render_draw_data(igGetDrawData());

            version(UIViewports) {
                
                // Handle viewports
                if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) {
                    SDL_Window* currentWindow = SDL_GL_GetCurrentWindow();
                    SDL_GLContext currentCtx = SDL_GL_GetCurrentContext();
                    igUpdatePlatformWindows();
                    igRenderPlatformWindowsDefault();
                    SDL_GL_MakeCurrent(currentWindow, currentCtx);
                }
            }

            version (SafeThrottling) {
                if (throttlingRate > 1) {
                    // Write image to back buffer.
                    auto size = io.DisplaySize;
                    if (fbo == 0) { 
                        onResized(cast(int)size.x, cast(int)size.y); 
                    }
                    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
                    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbo);
                    glBlitFramebuffer(0, 0, cast(int)size.x, cast(int)size.y, 0, 0, cast(int)size.x, cast(int)size.y, GL_COLOR_BUFFER_BIT, GL_NEAREST);
                }
            }

            // Swap this window
            SDL_GL_SwapWindow(window);

            // Clean up dialog windows
            uiImCleanupDialogs();            
        }
        version (SafeThrottling) {
            if (throttlingRate == 0 || renderThrottlingCount % throttlingRate == 0) {
                doUpdate();
            } else {
                // Write from back buffer.
                auto size = io.DisplaySize;
                if (fbo == 0) { 
                    onResized(cast(int)size.x, cast(int)size.y); 
                }
                glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
                glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
                glBlitFramebuffer(0, 0, cast(int)size.x, cast(int)size.y, 0, 0, cast(int)size.x, cast(int)size.y, GL_COLOR_BUFFER_BIT, GL_NEAREST);
                SDL_GL_SwapWindow(window);
            }
            renderThrottlingCount++;
        } else {
            doUpdate();
        }
    }

    string getWindowHandle() {
        version (linux) {
            SDL_SysWMinfo info;
            auto res = SDL_GetWindowWMInfo(window, &info);
            if (info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_X11) {
                import std.conv : to;
                return "x11:" ~ info.info.x11.window.to!string(16);
            }
        }
        return "";
    }

    /**
        Forces the window to be focused
    */
    override
    void focus() {
        SDL_SetWindowInputFocus(window);
    }

    /**
        Closes the Window
    */
    override
    void close() {
        done = true;
        onClosed();
    }

    /**
        Updates the window
    */
    override
    bool isAlive() {
        return !done;
    }

    /**
        Window width
    */
    override
    int width() {
        return width_;
    }

    /**
        Window height
    */
    override
    int height() {
        return height_;
    }

    void setIcon(ShallowTexture tex) {
        SDL_SysWMinfo info;
        SDL_GetWindowWMInfo(window, &info);
        bool isWayland = info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_WAYLAND;
        version(linux) {
            if (!isWayland) {
                SDL_SetWindowIcon(window, SDL_CreateRGBSurfaceWithFormatFrom(tex.data.ptr, tex.width, tex.height, 32, 4*tex.width,  SDL_PIXELFORMAT_RGBA32));
            }
        }
    }

    override
    void onResized(int width, int height) {
        version(SafeThrottling) {
            if (fboTexture) {
                glDeleteTextures(1, &fboTexture);
            }
            if (fbo) {
                glDeleteFramebuffers(1, &fbo);
            }
            if (throttlingRate > 1) {
                glGenFramebuffers(1, &fbo);
                glGenTextures(1, &fboTexture);

                glBindTexture(GL_TEXTURE_2D, fboTexture);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glBindFramebuffer(GL_FRAMEBUFFER, fbo);
                glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fboTexture, 0);
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
            }
        }
    }
}
