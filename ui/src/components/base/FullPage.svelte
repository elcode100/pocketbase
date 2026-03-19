<script>
    import { onMount } from "svelte";
    import PageWrapper from "@/components/base/PageWrapper.svelte";

    export let nobranding = false;

    let pbconsoleUrl = "";

    // Load PBConsole redirect URL from pb_hooks API at runtime
    onMount(async () => {
        try {
            const res = await fetch("/api/pbconsole-url");
            if (res.ok) {
                const data = await res.json();
                if (data?.url) pbconsoleUrl = data.url;
            }
        } catch {}
    });
</script>

<PageWrapper class="full-page" center>
    <div class="wrapper wrapper-sm m-b-xl panel-wrapper">
        {#if !nobranding}
            <div class="block txt-center m-b-lg">
                <!-- svelte-ignore a11y-click-events-have-key-events -->
                <!-- svelte-ignore a11y-no-static-element-interactions -->
                <figure
                    class="logo"
                    class:clickable={!!pbconsoleUrl}
                    on:click={() => { if (pbconsoleUrl) window.location.href = pbconsoleUrl; }}
                >
                    <img
                        src="{import.meta.env.BASE_URL}images/logo.svg"
                        alt="PocketBase logo"
                        width="40"
                        height="40"
                    />
                    <span class="txt">Pocket<strong>Base</strong></span>
                </figure>
            </div>
            <div class="clearfix" />
        {/if}

        <slot />
    </div>
</PageWrapper>

<style>
    .panel-wrapper {
        animation: slideIn 200ms;
    }
    .logo.clickable {
        cursor: pointer;
    }
</style>
