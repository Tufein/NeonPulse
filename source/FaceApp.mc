import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new FaceView() ];
    }

    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}
