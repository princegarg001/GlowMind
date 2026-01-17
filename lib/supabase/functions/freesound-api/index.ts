import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

const FREESOUND_BASE_URL = "https://freesound.org/apiv2";

// Mood to search query mapping
const MOOD_QUERIES: Record<string, { query: string; minDuration: number; maxDuration: number }> = {
  sleep: {
    query: "ambient sleep relaxing soft calm",
    minDuration: 60,
    maxDuration: 600,
  },
  study: {
    query: "lo-fi ambient background focus concentration",
    minDuration: 120,
    maxDuration: 600,
  },
  party: {
    query: "upbeat electronic dance energy beat",
    minDuration: 120,
    maxDuration: 300,
  },
  meditate: {
    query: "meditation zen calm peaceful tibetan bowl",
    minDuration: 60,
    maxDuration: 600,
  },
  deepFocus: {
    query: "binaural focus concentration ambient white noise",
    minDuration: 180,
    maxDuration: 600,
  },
  nature: {
    query: "nature forest rain ocean birds stream water",
    minDuration: 60,
    maxDuration: 600,
  },
};

interface FreesoundSearchResult {
  id: number;
  name: string;
  url: string;
  previews: {
    "preview-hq-mp3": string;
    "preview-lq-mp3": string;
    "preview-hq-ogg": string;
    "preview-lq-ogg": string;
  };
  duration: number;
  username: string;
  license: string;
  tags: string[];
  description: string;
  avg_rating: number;
  num_ratings: number;
}

interface FreesoundSearchResponse {
  count: number;
  next: string | null;
  previous: string | null;
  results: FreesoundSearchResult[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const apiKey = Deno.env.get("FREESOUND_API_KEY");
    
    if (!apiKey) {
      console.error("FREESOUND_API_KEY not found in environment");
      return new Response(
        JSON.stringify({ 
          error: "FREESOUND_API_KEY not configured",
          message: "Please add your Freesound API key in Supabase Edge Function secrets"
        }),
        { 
          status: 500, 
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" } 
        }
      );
    }

    console.log("API Key found, processing request...");

    const body = await req.json();
    console.log("Request body:", JSON.stringify(body));
    
    const { action, mood, soundId, page = 1, pageSize = 15, query } = body;

    let response;

    switch (action) {
      case "search":
        console.log(`Searching sounds - mood: ${mood}, query: ${query}, page: ${page}`);
        response = await searchSounds(apiKey, mood, page, pageSize, query);
        break;
      
      case "getSoundDetails":
        console.log(`Getting sound details for ID: ${soundId}`);
        response = await getSoundDetails(apiKey, soundId);
        break;
      
      case "getDownloadUrl":
        console.log(`Getting download URL for ID: ${soundId}`);
        response = await getDownloadUrl(apiKey, soundId);
        break;
      
      case "getSimilarSounds":
        console.log(`Getting similar sounds for ID: ${soundId}`);
        response = await getSimilarSounds(apiKey, soundId, pageSize);
        break;
      
      default:
        console.error(`Invalid action: ${action}`);
        return new Response(
          JSON.stringify({ error: "Invalid action", validActions: ["search", "getSoundDetails", "getDownloadUrl", "getSimilarSounds"] }),
          { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
    }

    console.log("Response successful");
    return new Response(
      JSON.stringify(response),
      { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal server error" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});

async function searchSounds(
  apiKey: string, 
  mood: string | undefined, 
  page: number, 
  pageSize: number,
  customQuery?: string
) {
  let searchQuery: string;
  let filter = "";

  if (mood && MOOD_QUERIES[mood]) {
    const moodConfig = MOOD_QUERIES[mood];
    searchQuery = moodConfig.query;
    filter = `duration:[${moodConfig.minDuration} TO ${moodConfig.maxDuration}]`;
  } else if (customQuery) {
    searchQuery = customQuery;
  } else {
    searchQuery = "ambient relaxing";
  }

  const params = new URLSearchParams({
    query: searchQuery,
    page: page.toString(),
    page_size: pageSize.toString(),
    fields: "id,name,url,previews,duration,username,license,tags,description,avg_rating,num_ratings",
    sort: "rating_desc",
  });

  if (filter) {
    params.append("filter", filter);
  }

  const url = `${FREESOUND_BASE_URL}/search/text/?${params.toString()}`;
  console.log(`Freesound search URL: ${url}`);
  
  const response = await fetch(url, {
    headers: {
      "Authorization": `Token ${apiKey}`,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`Freesound API error: ${response.status} - ${errorText}`);
    throw new Error(`Freesound API error: ${response.status} - ${errorText}`);
  }

  const data: FreesoundSearchResponse = await response.json();
  console.log(`Found ${data.count} sounds`);

  // Transform results to a cleaner format
  return {
    count: data.count,
    page,
    pageSize,
    hasNext: data.next !== null,
    hasPrevious: data.previous !== null,
    results: data.results.map((sound) => ({
      id: sound.id,
      name: sound.name,
      url: sound.url,
      previewUrl: sound.previews?.["preview-hq-mp3"] || sound.previews?.["preview-lq-mp3"],
      previewUrlLq: sound.previews?.["preview-lq-mp3"],
      duration: sound.duration,
      username: sound.username,
      license: sound.license,
      tags: sound.tags,
      description: sound.description,
      rating: sound.avg_rating,
      numRatings: sound.num_ratings,
      attribution: `Sound "${sound.name}" by ${sound.username} - freesound.org (${sound.license})`,
    })),
  };
}

async function getSoundDetails(apiKey: string, soundId: number) {
  if (!soundId) {
    throw new Error("soundId is required");
  }

  const url = `${FREESOUND_BASE_URL}/sounds/${soundId}/?fields=id,name,url,previews,duration,username,license,tags,description,avg_rating,num_ratings,download,similar_sounds,images`;

  const response = await fetch(url, {
    headers: {
      "Authorization": `Token ${apiKey}`,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Freesound API error: ${response.status} - ${errorText}`);
  }

  const sound = await response.json();

  return {
    id: sound.id,
    name: sound.name,
    url: sound.url,
    previewUrl: sound.previews?.["preview-hq-mp3"] || sound.previews?.["preview-lq-mp3"],
    previewUrlLq: sound.previews?.["preview-lq-mp3"],
    duration: sound.duration,
    username: sound.username,
    license: sound.license,
    tags: sound.tags,
    description: sound.description,
    rating: sound.avg_rating,
    numRatings: sound.num_ratings,
    downloadUrl: sound.download,
    images: sound.images,
    attribution: `Sound "${sound.name}" by ${sound.username} - freesound.org (${sound.license})`,
  };
}

async function getDownloadUrl(apiKey: string, soundId: number) {
  if (!soundId) {
    throw new Error("soundId is required");
  }

  const url = `${FREESOUND_BASE_URL}/sounds/${soundId}/?fields=id,name,previews,download`;

  const response = await fetch(url, {
    headers: {
      "Authorization": `Token ${apiKey}`,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Freesound API error: ${response.status} - ${errorText}`);
  }

  const sound = await response.json();

  return {
    id: sound.id,
    name: sound.name,
    previewHq: sound.previews?.["preview-hq-mp3"],
    previewLq: sound.previews?.["preview-lq-mp3"],
    streamUrl: sound.previews?.["preview-hq-mp3"] || sound.previews?.["preview-lq-mp3"],
  };
}

async function getSimilarSounds(apiKey: string, soundId: number, pageSize: number = 10) {
  if (!soundId) {
    throw new Error("soundId is required");
  }

  const url = `${FREESOUND_BASE_URL}/sounds/${soundId}/similar/?page_size=${pageSize}&fields=id,name,url,previews,duration,username,license,tags`;

  const response = await fetch(url, {
    headers: {
      "Authorization": `Token ${apiKey}`,
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Freesound API error: ${response.status} - ${errorText}`);
  }

  const data = await response.json();

  return {
    count: data.count,
    results: data.results.map((sound: FreesoundSearchResult) => ({
      id: sound.id,
      name: sound.name,
      url: sound.url,
      previewUrl: sound.previews?.["preview-hq-mp3"] || sound.previews?.["preview-lq-mp3"],
      duration: sound.duration,
      username: sound.username,
      license: sound.license,
      tags: sound.tags,
      attribution: `Sound "${sound.name}" by ${sound.username} - freesound.org (${sound.license})`,
    })),
  };
}