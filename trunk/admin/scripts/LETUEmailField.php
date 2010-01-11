<?php
    require_once($path."OpenSiteAdmin/scripts/classes/Field.php");

    class LETUEmailField extends Field {
        function process() {
            $ret = parent::process();
            $value = $this->getValue();
            if(!strchr($value, "@")) {
                $value .= "@letu.edu";
                $this->setValue($value);
            } elseif(substr($value, -9) != "@letu.edu") {
                $this->errorText .= "Email must be a LeTourneau address";
                return false;
            }
            return $ret;
        }
    }
?>