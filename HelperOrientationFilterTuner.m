classdef HelperOrientationFilterTuner < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ComplementaryFilterTunerFigure    matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        AccelerometerGainSliderLabel  matlab.ui.control.Label
        AccelerometerGainSlider       matlab.ui.control.Slider
        MagnetometerGainSliderLabel   matlab.ui.control.Label
        MagnetometerGainSlider        matlab.ui.control.Slider
        AccelerometerWeightValue      matlab.ui.control.NumericEditField
        MagnetometerWeightValue       matlab.ui.control.NumericEditField
        RightPanel                    matlab.ui.container.Panel
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public)
        compfilt % complementary filter
        viewer
    end
    
    methods (Access = public)
        
        function update(app, q)
            
            app.viewer.Orientation = q(end);
            drawnow('limitrate');
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, filt)
            app.compfilt = filt;
            app.AccelerometerGainSlider.Value = filt.AccelerometerGain;
            app.AccelerometerWeightValue.Value = filt.AccelerometerGain;
            app.MagnetometerGainSlider.Value = filt.MagnetometerGain;
            app.MagnetometerWeightValue.Value = filt.MagnetometerGain;
            
            ax = axes(app.RightPanel);
            app.viewer = fusion.internal.plotpose(ax, 'NED');
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.ComplementaryFilterTunerFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Value changing function: AccelerometerGainSlider
        function AccelerometerGainSliderValueChanging(app, event)
            changingValue = event.Value;
            app.compfilt.AccelerometerGain = changingValue;
            app.AccelerometerWeightValue.Value = changingValue;
        end

        % Value changed function: AccelerometerGainSlider
        function AccelerometerGainSliderValueChanged(app, event)
            value = app.AccelerometerGainSlider.Value;
            app.compfilt.AccelerometerGain = value;
            app.AccelerometerWeightValue.Value = value;
        end

        % Value changing function: MagnetometerGainSlider
        function MagnetometerGainSliderValueChanging(app, event)
            changingValue = event.Value;
            app.compfilt.MagnetometerGain = changingValue;
            app.MagnetometerWeightValue.Value = changingValue;
        end

        % Value changed function: MagnetometerGainSlider
        function MagnetometerGainSliderValueChanged(app, event)
            value = app.MagnetometerGainSlider.Value;
            app.compfilt.MagnetometerGain = value;
            app.MagnetometerWeightValue.Value = value;
        end

        % Value changed function: AccelerometerWeightValue
        function AccelerometerWeightValueValueChanged(app, event)
            value = app.AccelerometerWeightValue.Value;
            app.compfilt.AccelerometerGain;
            app.AccelerometerGainSlider.Value = value;
        end

        % Value changed function: MagnetometerWeightValue
        function MagnetometerWeightValueValueChanged(app, event)
            value = app.MagnetometerWeightValue.Value;
            app.compfilt.MagnetometerGain = value;
            app.MagnetometerGainSlider.Value = value;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ComplementaryFilterTunerFigure and hide until all components are created
            app.ComplementaryFilterTunerFigure = uifigure('Visible', 'off');
            app.ComplementaryFilterTunerFigure.AutoResizeChildren = 'off';
            app.ComplementaryFilterTunerFigure.Position = [100 100 640 480];
            app.ComplementaryFilterTunerFigure.Name = 'Complementary Filter Tuner';
            app.ComplementaryFilterTunerFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.ComplementaryFilterTunerFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create AccelerometerGainSliderLabel
            app.AccelerometerGainSliderLabel = uilabel(app.LeftPanel);
            app.AccelerometerGainSliderLabel.HorizontalAlignment = 'right';
            app.AccelerometerGainSliderLabel.Position = [3 331 83 28];
            app.AccelerometerGainSliderLabel.Text = {'Accelerometer'; 'Gain'};

            % Create AccelerometerGainSlider
            app.AccelerometerGainSlider = uislider(app.LeftPanel);
            app.AccelerometerGainSlider.Limits = [0 1];
            app.AccelerometerGainSlider.ValueChangedFcn = createCallbackFcn(app, @AccelerometerGainSliderValueChanged, true);
            app.AccelerometerGainSlider.ValueChangingFcn = createCallbackFcn(app, @AccelerometerGainSliderValueChanging, true);
            app.AccelerometerGainSlider.Position = [107 346 99 3];

            % Create MagnetometerGainSliderLabel
            app.MagnetometerGainSliderLabel = uilabel(app.LeftPanel);
            app.MagnetometerGainSliderLabel.HorizontalAlignment = 'right';
            app.MagnetometerGainSliderLabel.Position = [3 150 83 28];
            app.MagnetometerGainSliderLabel.Text = {'Magnetometer'; 'Gain'};

            % Create MagnetometerGainSlider
            app.MagnetometerGainSlider = uislider(app.LeftPanel);
            app.MagnetometerGainSlider.Limits = [0 1];
            app.MagnetometerGainSlider.ValueChangedFcn = createCallbackFcn(app, @MagnetometerGainSliderValueChanged, true);
            app.MagnetometerGainSlider.ValueChangingFcn = createCallbackFcn(app, @MagnetometerGainSliderValueChanging, true);
            app.MagnetometerGainSlider.Position = [107 165 99 3];

            % Create AccelerometerWeightValue
            app.AccelerometerWeightValue = uieditfield(app.LeftPanel, 'numeric');
            app.AccelerometerWeightValue.ValueDisplayFormat = '%11.2g';
            app.AccelerometerWeightValue.ValueChangedFcn = createCallbackFcn(app, @AccelerometerWeightValueValueChanged, true);
            app.AccelerometerWeightValue.Position = [34 295 52 22];

            % Create MagnetometerWeightValue
            app.MagnetometerWeightValue = uieditfield(app.LeftPanel, 'numeric');
            app.MagnetometerWeightValue.ValueDisplayFormat = '%11.2g';
            app.MagnetometerWeightValue.ValueChangedFcn = createCallbackFcn(app, @MagnetometerWeightValueValueChanged, true);
            app.MagnetometerWeightValue.Position = [34 114 52 22];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Show the figure after all components are created
            app.ComplementaryFilterTunerFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = HelperOrientationFilterTuner(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ComplementaryFilterTunerFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ComplementaryFilterTunerFigure)
        end
    end
end