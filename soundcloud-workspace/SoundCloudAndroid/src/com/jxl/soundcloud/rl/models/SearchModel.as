package com.jxl.soundcloud.rl.models
{
	import com.jxl.soundcloud.events.AuthorizeEvent;
	import com.jxl.soundcloud.events.SearchEvent;
	import com.jxl.soundcloud.events.SearchServiceEvent;
	import com.jxl.soundcloud.services.SearchService;
	
	import org.robotlegs.mvcs.Actor;
	
	public class SearchModel extends Actor
	{
		[Inject]
		public var searchService:SearchService;
		
		private var _searchResults:Array;
		
		public function get searchResults():Array { return _searchResults; }
		
		public function SearchModel()
		{
			super();
		}
		
		public function search(searchString:String):void
		{
			_searchResults = null;
			eventMap.mapListener(searchService, SearchServiceEvent.SEARCH_SUCCESS, onSearchSuccess, SearchServiceEvent);
			eventMap.mapListener(searchService, SearchServiceEvent.SEARCH_ERROR, onSearchError, SearchServiceEvent);
			eventMap.mapListener(searchService, AuthorizeEvent.UNAUTHORIZED, onUnauthorized, AuthorizeEvent);
			searchService.search(searchString);
		}
		
		public function cancelLast():void
		{
			searchService.cancel();
		}
		
		private function onUnauthorized(event:AuthorizeEvent):void
		{
			dispatch(event);
		}
		
		private function onSearchSuccess(event:SearchServiceEvent):void
		{
			setSearchResults(event.searchResults);
		}
		
		private function onSearchError(event:SearchServiceEvent):void
		{
			dispatch(event);
		}
		
		private function setSearchResults(searchResults:Array):void
		{
			if(searchResults != _searchResults)
			{
				_searchResults = searchResults;
				var evt:SearchEvent = new SearchEvent(SearchEvent.SEARCH_RESULTS_CHANGED);
				evt.searchResults = _searchResults;
				dispatch(evt);
			}
		}
	}
}