"""
* Purpose: MCP server for web search and knowledge base operations
* Issues & Complexity Summary: Multi-source search aggregation with result ranking
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~250
  - Core Algorithm Complexity: Medium (search result aggregation + ranking)
  - Dependencies: Multiple search APIs + web scraping
  - State Management Complexity: Medium (result caching)
  - Novelty/Uncertainty Factor: Medium
* AI Pre-Task Self-Assessment: 80%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 88%
* Overall Result Score: 84%
* Key Variances/Learnings: Complex search result aggregation and relevance scoring
* Last Updated: 2025-06-26
"""

import asyncio
import logging
import time
import hashlib
from typing import Dict, Any, Optional, List
import os
import json

import httpx
from bs4 import BeautifulSoup
import redis.asyncio as redis

logger = logging.getLogger(__name__)


class SearchMCPServer:
    """MCP server for web search and knowledge operations"""

    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.redis_client = redis_client
        self.server_name = "search"
        self.is_running = False
        self.capabilities = [
            "web_search",
            "knowledge_query",
            "fact_check",
            "research",
            "summarize_results",
        ]

        # Search service configurations
        self.search_configs = {
            "duckduckgo": {
                "base_url": "https://api.duckduckgo.com/",
                "enabled": True,
                "rate_limit": 100,  # requests per hour
            },
            "bing": {
                "base_url": "https://api.bing.microsoft.com/v7.0/search",
                "api_key": os.getenv("BING_SEARCH_API_KEY", ""),
                "enabled": bool(os.getenv("BING_SEARCH_API_KEY")),
                "rate_limit": 1000,
            },
            "serp": {
                "base_url": "https://serpapi.com/search",
                "api_key": os.getenv("SERP_API_KEY", ""),
                "enabled": bool(os.getenv("SERP_API_KEY")),
                "rate_limit": 100,
            },
        }

        # Cache settings
        self.cache_ttl = 3600  # 1 hour
        self.max_results_per_source = 10

        # HTTP client
        self.http_client = None

    async def initialize(self):
        """Initialize the search MCP server"""
        logger.info("Initializing Search MCP Server...")

        try:
            # Initialize HTTP client
            self.http_client = httpx.AsyncClient(
                timeout=httpx.Timeout(30.0),
                limits=httpx.Limits(max_keepalive_connections=20, max_connections=100),
            )

            # Test available search services
            await self._test_search_services()

            logger.info("Search MCP Server initialized successfully")

        except Exception as e:
            logger.error(f"Search MCP Server initialization failed: {str(e)}")
            raise

    async def start(self):
        """Start the search MCP server"""
        self.is_running = True
        logger.info("Search MCP Server started")

    async def shutdown(self):
        """Shutdown the search MCP server"""
        self.is_running = False

        if self.http_client:
            await self.http_client.aclose()

        logger.info("Search MCP Server shut down")

    async def ping(self):
        """Health check for the search server"""
        if not self.is_running:
            raise RuntimeError("Search MCP Server is not running")
        return {"status": "healthy", "timestamp": time.time()}

    async def web_search(
        self,
        query: str,
        num_results: int = 10,
        search_type: str = "general",
        safe_search: bool = True,
        language: str = "en",
    ) -> Dict[str, Any]:
        """Perform web search across multiple sources"""
        start_time = time.time()

        try:
            # Check cache first
            cache_key = self._get_cache_key(
                "web_search", query, num_results, search_type
            )

            if self.redis_client:
                cached_result = await self.redis_client.get(cache_key)
                if cached_result:
                    logger.info(f"Returning cached search result for: {query}")
                    return json.loads(cached_result)

            # Aggregate results from multiple sources
            all_results = []

            # Search with available services
            search_tasks = []

            if self.search_configs["duckduckgo"]["enabled"]:
                search_tasks.append(
                    self._search_duckduckgo(query, num_results, safe_search)
                )

            if self.search_configs["bing"]["enabled"]:
                search_tasks.append(
                    self._search_bing(query, num_results, safe_search, language)
                )

            if self.search_configs["serp"]["enabled"]:
                search_tasks.append(self._search_serp(query, num_results, safe_search))

            # Execute searches concurrently
            search_results = await asyncio.gather(*search_tasks, return_exceptions=True)

            # Aggregate results
            for result in search_results:
                if isinstance(result, Exception):
                    logger.error(f"Search service error: {str(result)}")
                    continue

                if result and "results" in result:
                    all_results.extend(result["results"])

            # Rank and deduplicate results
            ranked_results = self._rank_and_deduplicate(all_results, query)

            # Limit to requested number of results
            final_results = ranked_results[:num_results]

            processing_time = time.time() - start_time

            search_response = {
                "query": query,
                "results": final_results,
                "total_results": len(final_results),
                "processing_time": processing_time,
                "search_engines": [
                    name
                    for name, config in self.search_configs.items()
                    if config["enabled"]
                ],
                "cached": False,
            }

            # Cache the result
            if self.redis_client:
                await self.redis_client.setex(
                    cache_key, self.cache_ttl, json.dumps(search_response)
                )

            return search_response

        except Exception as e:
            logger.error(f"Web search failed: {str(e)}")
            raise

    async def knowledge_query(
        self, query: str, sources: List[str] = None, depth: str = "basic"
    ) -> Dict[str, Any]:
        """Query knowledge bases and authoritative sources"""
        try:
            # Define knowledge sources
            knowledge_sources = sources or ["wikipedia", "britannica", "academic"]

            results = []

            # Search Wikipedia for encyclopedic information
            if "wikipedia" in knowledge_sources:
                wiki_results = await self._search_wikipedia(query)
                if wiki_results:
                    results.extend(wiki_results)

            # Add more knowledge sources as needed

            return {
                "query": query,
                "sources": knowledge_sources,
                "results": results,
                "depth": depth,
                "confidence_score": self._calculate_confidence(results),
            }

        except Exception as e:
            logger.error(f"Knowledge query failed: {str(e)}")
            raise

    async def fact_check(
        self, statement: str, sources: List[str] = None
    ) -> Dict[str, Any]:
        """Fact-check a statement against reliable sources"""
        try:
            # Perform targeted search for fact-checking
            search_results = await self.web_search(
                query=f"fact check: {statement}", num_results=20, search_type="news"
            )

            # Analyze results for fact-checking indicators
            fact_check_sources = []
            credibility_indicators = []

            for result in search_results["results"]:
                # Look for fact-checking websites
                if any(
                    domain in result["url"].lower()
                    for domain in [
                        "snopes.com",
                        "factcheck.org",
                        "politifact.com",
                        "reuters.com/fact-check",
                    ]
                ):
                    fact_check_sources.append(result)

                # Look for credibility indicators
                if any(
                    indicator in result["snippet"].lower()
                    for indicator in [
                        "verified",
                        "confirmed",
                        "debunked",
                        "false",
                        "true",
                        "misleading",
                    ]
                ):
                    credibility_indicators.append(result)

            return {
                "statement": statement,
                "fact_check_sources": fact_check_sources,
                "credibility_indicators": credibility_indicators,
                "confidence_level": "high" if len(fact_check_sources) > 0 else "medium",
                "recommendation": (
                    "Verify with multiple sources"
                    if len(fact_check_sources) == 0
                    else "Fact-check sources available"
                ),
            }

        except Exception as e:
            logger.error(f"Fact checking failed: {str(e)}")
            raise

    async def _search_duckduckgo(
        self, query: str, num_results: int, safe_search: bool
    ) -> Dict[str, Any]:
        """Search using DuckDuckGo Instant Answer API"""
        try:
            params = {
                "q": query,
                "format": "json",
                "safe_search": "strict" if safe_search else "off",
                "no_html": "1",
                "skip_disambig": "1",
            }

            response = await self.http_client.get(
                self.search_configs["duckduckgo"]["base_url"], params=params
            )
            response.raise_for_status()

            data = response.json()
            results = []

            # Process DuckDuckGo results
            if data.get("RelatedTopics"):
                for topic in data["RelatedTopics"][:num_results]:
                    if isinstance(topic, dict) and "Text" in topic:
                        results.append(
                            {
                                "title": topic.get("Text", "")[:100],
                                "url": topic.get("FirstURL", ""),
                                "snippet": topic.get("Text", ""),
                                "source": "duckduckgo",
                                "relevance_score": 0.8,
                            }
                        )

            return {"results": results, "source": "duckduckgo"}

        except Exception as e:
            logger.error(f"DuckDuckGo search failed: {str(e)}")
            return {"results": [], "source": "duckduckgo"}

    async def _search_bing(
        self, query: str, num_results: int, safe_search: bool, language: str
    ) -> Dict[str, Any]:
        """Search using Bing Search API"""
        try:
            if not self.search_configs["bing"]["api_key"]:
                return {"results": [], "source": "bing"}

            headers = {
                "Ocp-Apim-Subscription-Key": self.search_configs["bing"]["api_key"]
            }

            params = {
                "q": query,
                "count": min(num_results, 50),
                "mkt": f"{language}-US",
                "safeSearch": "Strict" if safe_search else "Off",
            }

            response = await self.http_client.get(
                self.search_configs["bing"]["base_url"], headers=headers, params=params
            )
            response.raise_for_status()

            data = response.json()
            results = []

            if "webPages" in data and "value" in data["webPages"]:
                for item in data["webPages"]["value"]:
                    results.append(
                        {
                            "title": item.get("name", ""),
                            "url": item.get("url", ""),
                            "snippet": item.get("snippet", ""),
                            "source": "bing",
                            "relevance_score": 0.9,
                        }
                    )

            return {"results": results, "source": "bing"}

        except Exception as e:
            logger.error(f"Bing search failed: {str(e)}")
            return {"results": [], "source": "bing"}

    async def _search_serp(
        self, query: str, num_results: int, safe_search: bool
    ) -> Dict[str, Any]:
        """Search using SerpApi"""
        try:
            if not self.search_configs["serp"]["api_key"]:
                return {"results": [], "source": "serp"}

            params = {
                "q": query,
                "api_key": self.search_configs["serp"]["api_key"],
                "engine": "google",
                "num": min(num_results, 100),
                "safe": "active" if safe_search else "off",
            }

            response = await self.http_client.get(
                self.search_configs["serp"]["base_url"], params=params
            )
            response.raise_for_status()

            data = response.json()
            results = []

            if "organic_results" in data:
                for item in data["organic_results"]:
                    results.append(
                        {
                            "title": item.get("title", ""),
                            "url": item.get("link", ""),
                            "snippet": item.get("snippet", ""),
                            "source": "google",
                            "relevance_score": 0.95,
                        }
                    )

            return {"results": results, "source": "serp"}

        except Exception as e:
            logger.error(f"SerpApi search failed: {str(e)}")
            return {"results": [], "source": "serp"}

    async def _search_wikipedia(self, query: str) -> List[Dict[str, Any]]:
        """Search Wikipedia for encyclopedic information"""
        try:
            # Wikipedia API search
            search_url = (
                "https://en.wikipedia.org/api/rest_v1/page/summary/"
                + query.replace(" ", "_")
            )

            response = await self.http_client.get(search_url)

            if response.status_code == 200:
                data = response.json()

                return [
                    {
                        "title": data.get("title", ""),
                        "url": data.get("content_urls", {})
                        .get("desktop", {})
                        .get("page", ""),
                        "snippet": data.get("extract", ""),
                        "source": "wikipedia",
                        "relevance_score": 1.0,
                        "type": "encyclopedic",
                    }
                ]

            return []

        except Exception as e:
            logger.error(f"Wikipedia search failed: {str(e)}")
            return []

    def _rank_and_deduplicate(self, results: List[Dict], query: str) -> List[Dict]:
        """Rank search results and remove duplicates"""
        # Remove duplicates based on URL
        seen_urls = set()
        unique_results = []

        for result in results:
            url = result.get("url", "")
            if url and url not in seen_urls:
                seen_urls.add(url)
                unique_results.append(result)

        # Simple ranking based on source reliability and relevance score
        def rank_score(result):
            base_score = result.get("relevance_score", 0.5)

            # Boost authoritative sources
            if any(
                domain in result.get("url", "").lower()
                for domain in ["wikipedia.org", "britannica.com", "gov", "edu"]
            ):
                base_score += 0.2

            # Boost results with query terms in title
            if query.lower() in result.get("title", "").lower():
                base_score += 0.1

            return base_score

        # Sort by rank score
        ranked_results = sorted(unique_results, key=rank_score, reverse=True)

        return ranked_results

    def _calculate_confidence(self, results: List[Dict]) -> float:
        """Calculate confidence score for knowledge query results"""
        if not results:
            return 0.0

        # Base confidence on number of authoritative sources
        authoritative_count = sum(
            1
            for result in results
            if any(
                domain in result.get("url", "").lower()
                for domain in ["wikipedia.org", "britannica.com", "gov", "edu"]
            )
        )

        return min(1.0, (authoritative_count / len(results)) + 0.3)

    def _get_cache_key(self, operation: str, *args) -> str:
        """Generate cache key for search operations"""
        key_data = f"{operation}:" + ":".join(str(arg) for arg in args)
        return f"search_cache:{hashlib.md5(key_data.encode()).hexdigest()}"

    async def _test_search_services(self):
        """Test available search services"""
        test_query = "test"

        # Test each configured service
        for service_name, config in self.search_configs.items():
            if not config["enabled"]:
                continue

            try:
                if service_name == "duckduckgo":
                    result = await self._search_duckduckgo(test_query, 1, True)
                elif service_name == "bing":
                    result = await self._search_bing(test_query, 1, True, "en")
                elif service_name == "serp":
                    result = await self._search_serp(test_query, 1, True)
                else:
                    continue

                if result and "results" in result:
                    logger.info(f"{service_name} search service test passed")
                else:
                    logger.warning(
                        f"{service_name} search service test returned no results"
                    )

            except Exception as e:
                logger.error(f"{service_name} search service test failed: {str(e)}")
                config["enabled"] = False

    async def get_server_status(self) -> Dict[str, Any]:
        """Get current server status"""
        enabled_services = [
            name for name, config in self.search_configs.items() if config["enabled"]
        ]

        return {
            "name": self.server_name,
            "status": "running" if self.is_running else "stopped",
            "capabilities": self.capabilities,
            "enabled_services": enabled_services,
            "cache_ttl": self.cache_ttl,
            "last_ping": time.time(),
        }
