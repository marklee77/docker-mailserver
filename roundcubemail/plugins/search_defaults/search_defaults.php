<?php
class search_defaults extends rcube_plugin
{
    function init()
    {
        $this->add_hook('login_after', array($this, 'set_search_defaults'));
    }
    function set_search_defaults($args)
    {
        $_SESSION['search_scope'] = 'all';
        $_SESSION['search_interval'] = '1Y';
    }
}
